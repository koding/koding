package awsprovider

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"koding/db/models"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/provider/koding"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/utils/object"

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
	Credential string          `bson:"credential,omitempty"`
	ModifiedAt time.Time       `bson:"modifiedAt,omitempty"`
	Status     MigrationStatus `bson:"status,omitempty"`

	SourceImageID   string        `bson:"sourceImageID,omitempty"`
	ImageID         string        `bson:"imageID,omitempty"`
	StackTemplateID bson.ObjectId `bson:"stackTemplateId,omitempty"`

	Error string `bson:"error,omitempty"`
}

// MigrateProvider
type MigrateProvider struct {
	Stack  *Stack
	Koding *koding.Provider
	Object *object.Builder
	Locker kloud.Locker
	Log    logging.Logger

	Status     map[bson.ObjectId]*MigrationMeta
	KodingMeta map[bson.ObjectId]*koding.Meta

	machines []*MigratedMachine
	mu       sync.Mutex // protects Machines
	start    time.Time
}

func diff(lhs []*models.Machine, rhs []string) []string {
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
func (mp *MigrateProvider) Migrate(ctx context.Context, req *kloud.MigrateRequest) (interface{}, error) {
	b := mp.Stack.Builder

	b.Stack = &stackplan.Stack{
		Machines: req.Machines,
		Credentials: map[string][]string{
			"aws": {req.Identifier},
		},
	}

	if rt, ok := kloud.RequestTraceFromContext(ctx); ok {
		rt.Hijack()
	}

	// TODO: eventer: build machines

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

		mp.Status[m.ObjectId] = status
	}

	// validate koding vm metadata
	var merr error
	for _, m := range b.Machines {
		meta, err := (&koding.Machine{Machine: m}).GetMeta()
		if err != nil {
			merr = multierror.Append(merr, fmt.Errorf("invalid metadata for %q: %s", m.Label, err))
			continue
		}

		if meta.InstanceId == "" {
			merr = multierror.Append(merr, fmt.Errorf("invalid metadata for %q: missing instance ID", m.Label))
			continue
		}

		if meta.Region == "" {
			merr = multierror.Append(merr, fmt.Errorf("invalid metadata for %q: missing region", m.Label))
			continue
		}

		mp.KodingMeta[m.ObjectId] = meta
	}

	if merr != nil {
		return nil, merr
	}

	// TODO: eventer: Build credentials

	if err := b.BuildCredentials(mp.Stack.Req.Method, mp.Stack.Req.Username, req.GroupName, []string{req.Identifier}); err != nil {
		return nil, err
	}

	cred, err := b.CredentialByProvider("aws")
	if err != nil {
		return nil, err
	}

	meta = cred.Meta.(*AwsMeta)

	if err := meta.BootstrapValid(); err != nil {
		// Bootstrap credential for the user if it wasn't
		// bootstrapped yet.
		b.Credentials = nil

		req := &kloud.BootstrapRequest{
			Provider:    "aws",
			Identifiers: []string{req.Identifier},
			GroupName:   req.GroupName,
		}

		if err := mp.Stack.bootstrap(req); err != nil {
			return nil, err
		}

		cred, err = b.CredentialByProvider("aws")
		if err != nil {
			return nil, err
		}

		meta = cred.Meta.(*AwsMeta)
	}

	// TODO: eventer: Lock machines & mark as stopped

	if err := mp.lock(); err != nil {
		return nil, err
	}

	if err := mp.updateStatus(); err != nil {
		mp.Log.Warning("%s", err) // only log, non-fatal error
	}

	go func() {
		method := strings.ToUpper(s.Req.Method)

		if err := mp.migrate(ctx, req, meta); err != nil {
			mp.Log.Error("======> %s finished with error (time: %s): '%s' <======", method,
				time.Since(mp.start), err)
		} else {
			mp.Log.Info("======> %s finished (time: %s) <======", method, time.Since(start))
		}
	}()

	return kloud.ControlResult{
		EventId: mp.Stack.Eventer.ID(),
	}, nil
}

func (mp *MigrateProvider) migrate(ctx context.Context, req *kloud.MigrateRequest, cred *AwsMeta) error {
	defer mp.unlock()

	if rt, ok := kloud.RequestTraceFromContext(ctx); ok {
		defer rt.Send()
	}

	var wg sync.WaitGroup
	wg.Add(len(m))

	for _, m := range mp.Stack.Builder.Machines {
		wg.Add(1)

		go func(m *models.Machine) {
			defer wg.Done()

			status := mp.Status[m.ObjectId]

			err := mp.migrateSingle(m, mp.KodingMeta[m.ObjectId], status, cred)

			status.ModifiedAt = time.Now()

			if err != nil {
				status.Error = err.Error()
				status.Status = stackplan.MigrationError
			} else {
				status.Error = ""
				status.Status = stackplan.MigrationMigrated
			}

			opts := &stackplan.UpdateMigrationOptions{
				MachineID: m.ObjectId,
				Meta:      status,
				Log:       mp.Log,
			}

			if err := mp.Stack.Builder.Database.UpdateMigration(opts); err != nil {
				mp.Log.Warning("unable to update migration status for %q: %s", m.Label, err)
			}
		}(m)
	}

	wg.Wait()

	if err := mp.Err(); err != nil {
		return err
	}

	// TODO: check for error, finalize, build template, database

	return nil
}

func (mp *MigrateProvider) migrateSingle(m *models.Machine, meta *koding.Meta,
	status *MigrationStatus, cred *AwsMeta) error {
	return nil // TODO
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
			merr = multierror.Append(merr, fmt.Error("error updating migration status for %q: %s", m.Label, err))
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

// Migrate
func (s *Stack) Migrate(ctx context.Context) (interface{}, error) {
	if s.m == nil {
		return nil, kloud.NewError(kloud.ErrProviderIsDisabled)
	}

	var arg kloud.MigrateRequest
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
