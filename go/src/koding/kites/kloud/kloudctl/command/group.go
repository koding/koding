package command

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	"koding/db/mongodb"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/utils/res"

	"github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
	"github.com/mitchellh/cli"
	"golang.org/x/net/context"
)

type Stage struct {
	Name     string    `json:"name,omitempty"`
	Start    time.Time `json:"start,omitempty"`
	Progress int       `json:"progress,omitempty"`
}

type Status struct {
	MachineID    string    `json:"machineId,omitempty"`
	MachineLabel string    `json:"machineLabel,omitempty"`
	Start        time.Time `json:"start,omitempty"`
	End          time.Time `json:"end,omitempty"`
	Stages       []Stage   `json:"stages,omitempty"`
	Err          error     `json:"err,omitempty"`
}

type Group struct {
	*res.Resource
}

func NewGroup() cli.CommandFactory {
	return func() (cli.Command, error) {
		f := NewFlag("group", "Lists/creates/deletes a group of machines")
		f.action = &Group{
			Resource: &res.Resource{
				Name:        "group",
				Description: "Lists/creates/deletes a group of machines",
				Commands: map[string]res.Command{
					"list":   new(GroupList),
					"create": new(GroupCreate),
					"delete": new(GroupDelete),
				},
			},
		}
		return f, nil
	}
}

func (g *Group) Action(args []string, k *kite.Client) error {
	ctx := context.Background()
	ctx = context.WithValue(ctx, kiteKey, k)
	ctx = context.WithValue(ctx, mongoKey, mongodb.NewMongoDB(envMongoURL()))
	g.Resource.ContextFunc = func([]string) context.Context { return ctx }
	return g.Resource.Main(args)
}

// GroupList implements the "kloudctl group list" subcommand.
type GroupList struct{}

func (*GroupList) Name() string {
	return "list"
}

func (cmd *GroupList) RegisterFlags(f *flag.FlagSet) {
}

func (cmd *GroupList) Run(ctx context.Context) error {
	return errors.New("TODO(rjeczalik)")
}

// GroupCreate implements the "kloudctl group create" subcommand.
type GroupCreate struct {
	file     string
	count    int
	throttle int
	output   string
}

func (*GroupCreate) Name() string {
	return "create"
}

func (cmd *GroupCreate) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.file, "f", "", "JSON-encoded Machine specification file.")
	f.IntVar(&cmd.count, "n", 1, "Number of machines to be created.")
	f.IntVar(&cmd.throttle, "t", 0, "Throttling - max number of machines to be concurrently created.")
	f.StringVar(&cmd.output, "o", "", "File where list of statuses for each build will be written.")
}

func (cmd *GroupCreate) Run(ctx context.Context) error {
	if cmd.throttle == 0 {
		cmd.throttle = cmd.count
	}
	_, db := fromContext(ctx)
	spec, err := ParseMachineSpec(cmd.file, nil)
	if err != nil {
		return err
	}
	if err := spec.BuildUserAndGroup(db); err != nil {
		return err
	}
	specs := make([]*MachineSpec, cmd.count)
	for i := range specs {
		specs[i] = spec.Copy()
	}
	// Index the machines.
	if len(specs) > 1 {
		for _, spec := range specs {
			i := shortUID()
			spec.Machine.Slug = fmt.Sprintf("%s-%s", spec.Machine.Slug, i)
			spec.Machine.Label = fmt.Sprintf("%s-%s", spec.Machine.Label, i)
		}
	}
	return cmd.createMachines(ctx, specs...)
}

func (cmd *GroupCreate) createMachines(ctx context.Context, specs ...*MachineSpec) error {
	buildch := make(chan *MachineSpec)
	resch := make(chan *Status, cmd.throttle)

	for range make([]struct{}, cmd.throttle) {
		go func() {
			for spec := range buildch {
				msg := fmt.Sprintf("Requesting to build %q", spec.Machine.Label)
				DefaultUi.Info(msg)
				resch <- createMachine(ctx, spec)
			}
		}()
	}

	go func() {
		for _, spec := range specs {
			buildch <- spec
		}
	}()

	var errs *multierror.Error
	var avg, max time.Duration
	var min = time.Hour
	s := make([]*Status, len(specs))
	for i := range s {
		s[i] = <-resch
		dur := s[i].End.Sub(s[i].Start)
		avg += dur
		if dur < min {
			min = dur
		}
		if dur > max {
			max = dur
		}
		if s[i].Err != nil {
			err := fmt.Errorf("Error building %q (%q): %s", s[i].MachineLabel, s[i].MachineID, s[i].Err)
			DefaultUi.Error(err.Error())
			errs = multierror.Append(errs, err)
		} else {
			msg := fmt.Sprintf("Building %q (%q) finished in %s.", s[i].MachineLabel, s[i].MachineID, dur)
			DefaultUi.Info(msg)
		}
	}
	avg = avg / time.Duration(len(specs))
	DefaultUi.Info(fmt.Sprintf("Build times: avg=%s, min=%s, max=%s", avg, min, max))
	if err := cmd.writeStatuses(s); err != nil {
		errs = multierror.Append(errs, err)
	}
	return errs.ErrorOrNil()
}

func createMachine(ctx context.Context, spec *MachineSpec) *Status {
	k, db := fromContext(ctx)
	if err := spec.BuildMachine(db); err != nil {
		return &Status{
			MachineLabel: spec.Machine.Label,
			Err:          err,
		}
	}
	start := time.Now()
	var stages []Stage
	newStatus := func(err error) *Status {
		return &Status{
			MachineID:    spec.Machine.ObjectId.Hex(),
			MachineLabel: spec.Machine.Label,
			Start:        start,
			Stages:       stages,
			End:          time.Now(),
			Err:          err,
		}
	}
	buildReq := &KloudArgs{
		MachineId: spec.Machine.ObjectId.Hex(),
		Provider:  spec.Machine.Provider,
		Username:  spec.Username(),
	}
	resp, err := k.Tell("build", buildReq)
	if err != nil {
		return newStatus(err)
	}
	var result kloud.ControlResult
	if err = resp.Unmarshal(&result); err != nil {
		return newStatus(err)
	}
	req := kloud.EventArgs{{
		Type:    "build",
		EventId: spec.Machine.ObjectId.Hex(),
	}}
	var last Stage
	for {
		resp, err := k.Tell("event", req)
		if err != nil {
			return newStatus(err)
		}
		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return newStatus(err)
		}
		if len(events) == 0 || events[0].Event == nil {
			return newStatus(errors.New("empty event response"))
		}
		if events[0].Event.Message != last.Name || events[0].Event.Percentage != last.Progress {
			last = Stage{
				Name:     events[0].Event.Message,
				Start:    events[0].Event.TimeStamp,
				Progress: events[0].Event.Percentage,
			}
			stages = append(stages, last)
		}
		if s := events[0].Event.Error; s != "" {
			return newStatus(errors.New(s))
		}
		if events[0].Event.Percentage == 100 {
			return newStatus(nil)
		}
		time.Sleep(defaultPollInterval)
	}
}

func (cmd *GroupCreate) writeStatuses(s []*Status) (err error) {
	var f *os.File
	if cmd.output == "" {
		f, err = ioutil.TempFile("", "kloudctl")
	} else {
		f, err = os.OpenFile(cmd.output, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, 0755)
	}
	if err != nil {
		return err
	}
	defer f.Close()
	err = nonil(json.NewEncoder(f).Encode(s), f.Sync(), f.Close())
	if err != nil {
		return err
	}
	DefaultUi.Info(fmt.Sprintf("Summary written to %q", f.Name()))
	return nil
}

// GroupDelete implememts the "kloudctl group delete" subcommand.
type GroupDelete struct{}

func (*GroupDelete) Name() string {
	return "delete"
}

func (cmd *GroupDelete) RegisterFlags(f *flag.FlagSet) {
}

func (cmd *GroupDelete) Run(ctx context.Context) error {
	return errors.New("TODO(rjeczalik)")
}

var kiteKey struct {
	byte `key:"kite"`
}

var mongoKey struct {
	byte `key:"mongo"`
}

func fromContext(ctx context.Context) (*kite.Client, *mongodb.MongoDB) {
	return ctx.Value(kiteKey).(*kite.Client), ctx.Value(mongoKey).(*mongodb.MongoDB)
}

func envMongoURL() string {
	for _, env := range []string{"KLOUDCTL_MONGODB_URL", "KLOUD_MONGODB_URL"} {
		if s := os.Getenv(env); s != "" {
			return s
		}
	}
	return ""
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
