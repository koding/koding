package awsprovider

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"koding/db/models"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/provider/koding"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/utils/object"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/hashicorp/go-multierror"
	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2/bson"
)

// MigratedMachine
type MigratedMachine struct {
	Label        string `bson:"label"`
	Provider     string `bson:"provider"`
	Region       string `bson:"region"`
	SourceAMI    string `bson:"source_ami"`
	InstanceType string `bson:"instanceType"`
}

// MigrationMeta
type MigrationMeta struct {
	Credential string                    `bson:"credential,omitempty"`
	ModifiedAt time.Time                 `bson:"modifiedAt,omitempty"`
	Status     stackplan.MigrationStatus `bson:"status,omitempty"`

	SourceImageID string `bson:"sourceImageID,omitempty"`
	ImageID       string `bson:"imageID,omitempty"`

	Error string `bson:"error,omitempty"`
}

// MigrateProvider
type MigrateProvider struct {
	Stack  *Stack
	Koding *koding.Provider
	Object *object.Builder
	Locker stack.Locker
	Log    logging.Logger

	Status     map[bson.ObjectId]*MigrationMeta
	KodingMeta map[bson.ObjectId]*koding.Meta

	machines []*MigratedMachine
	mu       sync.Mutex // protects Machines
	start    time.Time
}

func diff(lhs map[string]*models.Machine, rhs []string) []string {
	all := make(map[string]struct{}, len(rhs))
	for _, id := range rhs {
		all[id] = struct{}{}
	}

	for _, m := range lhs {
		delete(all, m.ObjectId.Hex())
	}

	delete(all, "")

	missing := make([]string, 0, len(all))

	for id := range all {
		missing = append(missing, id)
	}

	return missing
}

// Migrate
func (mp *MigrateProvider) Migrate(ctx context.Context, req *stack.MigrateRequest) (interface{}, error) {
	mp.pushEvent(0, "Migration has started")

	resp, err := mp.migrate(ctx, req)
	if err != nil {
		mp.pushError(err)

		return nil, err
	}

	return resp, nil
}

func (mp *MigrateProvider) migrate(ctx context.Context, req *stack.MigrateRequest) (interface{}, error) {
	b := mp.Stack.Builder

	b.Stack = &stackplan.Stack{
		Machines: req.Machines,
		Credentials: map[string][]string{
			"aws": {req.Identifier},
		},
	}

	if rt, ok := stack.RequestTraceFromContext(ctx); ok {
		rt.Hijack()
	}

	mp.pushEvent(10, "Fetching and validating machines")

	if err := b.BuildMachines(ctx); err != nil {
		return nil, err
	}

	if missing := diff(b.Machines, req.Machines); len(missing) != 0 {
		return nil, fmt.Errorf("access denied to migrate the following machines: %v", missing)
	}

	// read persisted migration status
	for _, m := range b.Machines {
		status := &MigrationMeta{}

		if raw, ok := m.Meta["migration"]; ok {
			if err := mp.obj().Decode(raw, status); err != nil {
				mp.Log.Warning("unable to read migration details for %q: %s", m.Label, err)
			}

			mp.Log.Debug("read migration details for %q: %+v", m.Label, status)
		}

		if status.Credential != req.Identifier {
			// The lastly copied image belongs to a different account,
			// we need to copy it again.
			status.ImageID = ""
		}

		status.Credential = req.Identifier
		mp.Status[m.ObjectId] = status

		mp.Log.Debug("read %q machine status: %# v", m.ObjectId.Hex(), status)
	}

	// validate koding vm metadata
	var merr error
	for _, m := range b.Machines {
		m := &koding.Machine{
			Machine: m,
			Session: mp.Stack.Session,
			Log:     mp.Log,
		}

		meta, err := m.GetMeta()
		if err != nil {
			merr = multierror.Append(merr, fmt.Errorf("invalid metadata for %q: %s", m.Label, err))
			continue
		}

		if meta.InstanceId == "" {
			merr = multierror.Append(merr, fmt.Errorf("invalid metadata for %q: missing instance ID", m.Label))
			continue
		}

		if meta.Region == "" {
			mp.Log.Warning("empty region for %q; falling back to us-east-1", m.Label)

			meta.Region = "us-east-1"
		}

		mp.KodingMeta[m.ObjectId] = meta
		mp.Log.Debug("read %q machine metadata: %# v", m.ObjectId.Hex(), meta)
	}

	if merr != nil {
		return nil, merr
	}

	mp.pushEvent(20, "Fetching and validating credentials")

	if err := b.BuildCredentials(mp.Stack.Req.Method, mp.Stack.Req.Username, req.GroupName, []string{req.Identifier}); err != nil {
		return nil, err
	}

	cred, err := b.CredentialByProvider("aws")
	if err != nil {
		return nil, err
	}

	meta := cred.Meta.(*AwsMeta)

	if err := meta.BootstrapValid(); err != nil {
		// Bootstrap credential for the user if it wasn't
		// bootstrapped yet.
		b.Credentials = nil

		req := &stack.BootstrapRequest{
			Provider:    "aws",
			Identifiers: []string{req.Identifier},
			GroupName:   req.GroupName,
		}

		if _, err := mp.Stack.bootstrap(req); err != nil {
			return nil, err
		}

		cred, err = b.CredentialByProvider("aws")
		if err != nil {
			return nil, err
		}

		meta = cred.Meta.(*AwsMeta)
	}

	accountID, err := meta.AccountID()
	if err != nil {
		return nil, err
	}

	userOpts := &amazon.ClientOptions{
		Credentials: credentials.NewStaticCredentials(meta.AccessKey, meta.SecretKey, ""),
		Region:      meta.Region,
		Log:         mp.Log.New("useraws"),
	}

	user, err := amazon.NewClient(userOpts)
	if err != nil {
		return nil, err
	}

	if err := mp.lock(); err != nil {
		return nil, err
	}

	if err := mp.updateStatus(); err != nil {
		mp.Log.Warning("%s", err) // only log, non-fatal error
	}

	go func() {
		method := strings.ToUpper(mp.Stack.Req.Method)

		if err := mp.migrateAsync(ctx, req, accountID, user); err != nil {
			mp.Log.Error("======> %s finished with error (time: %s): '%s' <======", method,
				time.Since(mp.start), err)

			mp.pushError(err)
		} else {
			mp.Log.Info("======> %s finished (time: %s) <======", method, time.Since(mp.start))

			mp.pushEvent(100, "Migration has finished")
		}
	}()

	return stack.ControlResult{
		EventId: mp.Stack.Eventer.ID(),
	}, nil
}

func (mp *MigrateProvider) migrateAsync(ctx context.Context, req *stack.MigrateRequest,
	accountID string, user *amazon.Client) error {
	defer mp.unlock()

	if rt, ok := stack.RequestTraceFromContext(ctx); ok {
		defer rt.Send()
	}

	done := make(chan struct{})

	// TODO(rjeczalik): increment real progress, adding checkpoints e.g. after
	// WaitImage methods in migrateSingle method, for now it's faked.
	go func() {
		progress := 25
		ticker := time.NewTicker(time.Second * 5)
		defer ticker.Stop()

		for {
			select {
			case <-done:
				return
			case <-ticker.C:
				if progress < 90 {
					progress += 5
				}

				mp.pushEvent(progress, "Migrating Koding resources")
			}
		}
	}()

	var wg sync.WaitGroup

	for _, m := range mp.Stack.Builder.Machines {
		wg.Add(1)

		go func(m *models.Machine) {
			defer wg.Done()

			status := mp.Status[m.ObjectId]

			err := mp.migrateSingle(m, mp.KodingMeta[m.ObjectId], status, accountID, user)

			if err != nil {
				status.Error = err.Error()
				status.Status = stackplan.MigrationError
			} else {
				status.Error = ""
				status.Status = stackplan.MigrationMigrated
			}

			mp.updateMigration(m, status)
		}(m)
	}

	wg.Wait()
	close(done)

	if err := mp.Err(); err != nil {
		return err
	}

	mp.pushEvent(95, "Creating stack template")

	var (
		stack = newStackTemplate()
		n     = len(mp.Stack.Builder.Machines)
	)

	migrateOpts := &stackplan.MigrateOptions{
		MachineIDs: make([]bson.ObjectId, 0, n),
		Machines:   make([]interface{}, 0, n),
		Provider:   "aws",
		Identifier: req.Identifier,
		Username:   mp.Stack.Req.Username,
		GroupName:  req.GroupName,
		StackName:  req.StackName,
		Log:        mp.Log,
	}

	for _, m := range mp.Stack.Builder.Machines {
		meta := mp.KodingMeta[m.ObjectId]
		status := mp.Status[m.ObjectId]

		mm := &MigratedMachine{
			Label:        m.Label,
			Provider:     "aws",
			Region:       meta.Region,
			InstanceType: meta.InstanceType,
			SourceAMI:    status.ImageID,
		}

		stack.addInstance(mm)
		migrateOpts.Machines = append(migrateOpts.Machines, mm)
		migrateOpts.MachineIDs = append(migrateOpts.MachineIDs, m.ObjectId)
	}

	p, err := json.Marshal(stack)
	if err != nil {
		return err
	}

	mp.Log.Debug("stack template: %s", p)

	migrateOpts.Template = string(p)

	return mp.Stack.Builder.Database.Migrate(migrateOpts)
}

func (mp *MigrateProvider) migrateSingle(m *models.Machine, meta *koding.Meta,
	status *MigrationMeta, accountID string, user *amazon.Client) error {

	solo, err := mp.Koding.EC2Clients.Region(meta.Region)
	if err != nil {
		return err
	}

	var srcImage *amazon.Image

	if status.SourceImageID != "" {
		srcImage, err = solo.ImageByID(status.SourceImageID)
		if err != nil {
			mp.Log.Error("failed looking up %q image: %s; going to create again", status.SourceImageID, err)

			status.SourceImageID = ""
			srcImage = nil
		}
	}

	if status.SourceImageID == "" {
		name := fmt.Sprintf("migration-%s-%d", m.Uid, timestamp())

		status.SourceImageID, err = solo.CreateImage(meta.InstanceId, name)
		if err != nil {
			return err
		}

		mp.Log.Debug("created %q image for %s: %s", name, meta.InstanceId, status.SourceImageID)

		mp.updateMigration(m, status)
	}

	mp.Log.Debug("waiting for %q image to become ready", status.SourceImageID)

	if err := solo.WaitImage(status.SourceImageID); err != nil {
		return err
	}

	if srcImage == nil {
		srcImage, err = solo.ImageByID(status.SourceImageID)
		if err != nil {
			return err
		}
	}

	if err := solo.AllowCopyImage(srcImage, accountID); err != nil {
		return err
	}

	if status.ImageID == "" {
		name := fmt.Sprintf("koding-%s-%d", m.Uid, timestamp())

		status.ImageID, err = user.CopyImage(status.SourceImageID, meta.Region, name)
		if err != nil {
			return err
		}

		mp.Log.Debug("copied %q image to user AWS account: %s", status.SourceImageID, status.ImageID)

		mp.updateMigration(m, status)
	}

	mp.Log.Debug("waiting for %q image to become ready", status.ImageID)

	return user.WaitImage(status.ImageID)
}

func (mp *MigrateProvider) updateMigration(m *models.Machine, status *MigrationMeta) {
	status.ModifiedAt = time.Now()

	opts := &stackplan.UpdateMigrationOptions{
		MachineID: m.ObjectId,
		Meta:      status,
		Log:       mp.Log,
	}

	if err := mp.Stack.Builder.Database.UpdateMigration(opts); err != nil {
		// Not fatal, we can continue. This failure can make us creating
		// or copying the image again  when we eventually retry migration due to some
		// later failure.
		mp.Log.Error("failed to update status %+v for %q: %s", status, m.Label, err)
	}
}

func (mp *MigrateProvider) lock() error {
	var merr error

	for _, m := range mp.Stack.Builder.Machines {
		if err := mp.Locker.Lock(m.ObjectId.Hex()); err != nil {
			merr = multierror.Append(merr, fmt.Errorf("error locking %q: %s", m.Label, err))
		}
	}

	return merr
}

func (mp *MigrateProvider) unlock() {
	for _, m := range mp.Stack.Builder.Machines {
		mp.Locker.Unlock(m.ObjectId.Hex())
	}
}

func (mp *MigrateProvider) updateStatus() error {
	var merr error

	mp.start = time.Now()

	for _, m := range mp.Stack.Builder.Machines {
		m := &koding.Machine{
			Machine: m,
			Session: mp.Stack.Session,
			Log:     mp.Log,
		}

		if err := m.UpdateState("Stopped by migration", machinestate.Stopped); err != nil {
			merr = multierror.Append(merr, fmt.Errorf("error stopping %q: %s", m.Label, err))
		}

		meta := mp.Status[m.ObjectId]
		meta.ModifiedAt = mp.start
		meta.Status = stackplan.MigrationMigrating

		opts := &stackplan.UpdateMigrationOptions{
			MachineID: m.ObjectId,
			Meta:      meta,
			Log:       mp.Log,
		}

		if err := mp.Stack.Builder.Database.UpdateMigration(opts); err != nil {
			merr = multierror.Append(merr, fmt.Errorf("error updating migration status for %q: %s", m.Label, err))
		}
	}

	return merr
}

func (mp *MigrateProvider) obj() *object.Builder {
	if mp.Object != nil {
		return mp.Object
	}

	return object.HCLBuilder
}

func (mp *MigrateProvider) Err() error {
	var merr error

	for _, meta := range mp.Status {
		if meta.Error != "" {
			merr = multierror.Append(merr, errors.New(meta.Error))
		}
	}

	return merr
}

func (mp *MigrateProvider) pushEvent(percentage int, message string) {
	if mp.Stack.Eventer != nil {
		mp.Stack.Eventer.Push(&eventer.Event{
			Percentage: percentage,
			Status:     machinestate.Building,
			Message:    message,
		})
	}
}

func (mp *MigrateProvider) pushError(err error) {
	if mp.Stack.Eventer != nil {
		mp.Stack.Eventer.Push(&eventer.Event{
			Percentage: 100,
			Status:     machinestate.NotInitialized,
			Error:      err.Error(),
		})
	}
}

// Migrate
func (s *Stack) Migrate(ctx context.Context) (interface{}, error) {
	if s.m == nil {
		return nil, stack.NewError(stack.ErrProviderIsDisabled)
	}

	var arg stack.MigrateRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	method := strings.ToUpper(s.Req.Method)

	s.m.Log.Info("======> %s started <======", method)

	resp, err := s.m.Migrate(ctx, &arg)

	if err != nil {
		s.m.Log.Error("======> %s finished with error (time: %s): '%s' <======",
			method, time.Since(s.m.start), err)

		return nil, err
	}

	return resp, nil
}

func timestamp() int {
	return int(time.Now().UTC().UnixNano() / int64(time.Millisecond))
}

type stackTemplate struct {
	Provider map[string]interface{} `json:"provider"`
	Resource struct {
		Instances map[string]interface{} `json:"aws_instance"`
	} `json:"resource"`
}

type instance struct {
	InstanceType string            `json:"instance_type"`
	AMI          string            `json:"ami"`
	Tags         map[string]string `json:"tags"`
}

func newStackTemplate() *stackTemplate {
	s := &stackTemplate{
		Provider: map[string]interface{}{
			"aws": map[string]string{
				"access_key": "${var.aws_access_key}",
				"secret_key": "${var.aws_secret_key}",
			},
		},
	}

	s.Resource.Instances = make(map[string]interface{})

	return s
}

func (s *stackTemplate) addInstance(m *MigratedMachine) {
	s.Resource.Instances[m.Label] = &instance{
		InstanceType: m.InstanceType,
		AMI:          m.SourceAMI,
		Tags: map[string]string{
			"Name": "${var.koding_user_username}-${var.koding_group_slug}",
		},
	}
}
