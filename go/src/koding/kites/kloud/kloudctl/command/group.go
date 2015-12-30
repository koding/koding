package command

import (
	"errors"
	"flag"
	"fmt"
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
}

func (*GroupCreate) Name() string {
	return "create"
}

func (cmd *GroupCreate) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.file, "f", "", "JSON-encoded Machine specification file.")
	f.IntVar(&cmd.count, "n", 1, "Number of machines to be created.")
	f.IntVar(&cmd.throttle, "t", 0, "Throttling - max number of machines to be concurrently created.")
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

type createResponse struct {
	MachineID    string
	MachineLabel string
	Time         time.Duration
	Err          error
}

func (cmd *GroupCreate) createMachines(ctx context.Context, specs ...*MachineSpec) error {
	buildch := make(chan *MachineSpec)
	resch := make(chan *createResponse, cmd.throttle)

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
	var overall time.Duration
	for range specs {
		res := <-resch
		overall += res.Time
		if res.Err != nil {
			err := fmt.Errorf("Error building %q (%q): %s", res.MachineLabel,
				res.MachineID, res.Err)
			DefaultUi.Error(err.Error())
			errs = multierror.Append(errs, err)
		} else {
			msg := fmt.Sprintf("Building %q (%q) finished in %s.", res.MachineLabel,
				res.MachineID, res.Time)
			DefaultUi.Info(msg)
		}
	}
	DefaultUi.Info(fmt.Sprintf("Average build time: %s", overall/time.Duration(len(specs))))
	return errs.ErrorOrNil()
}

func createMachine(ctx context.Context, spec *MachineSpec) *createResponse {
	k, db := fromContext(ctx)
	if err := spec.BuildMachine(db); err != nil {
		return &createResponse{
			MachineLabel: spec.Machine.Label,
			Err:          err,
		}
	}
	start := time.Now()
	newResponse := func(err error) *createResponse {
		return &createResponse{
			MachineID:    spec.Machine.ObjectId.Hex(),
			MachineLabel: spec.Machine.Label,
			Time:         time.Now().Sub(start),
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
		return newResponse(err)
	}
	var result kloud.ControlResult
	if err = resp.Unmarshal(&result); err != nil {
		return newResponse(err)
	}
	req := kloud.EventArgs{{
		Type:    "build",
		EventId: spec.Machine.ObjectId.Hex(),
	}}
	for {
		resp, err := k.Tell("event", req)
		if err != nil {
			return newResponse(err)
		}
		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return newResponse(err)
		}
		if len(events) == 0 {
			return newResponse(errors.New("empty event response"))
		}
		if s := events[0].Event.Error; s != "" {
			return newResponse(errors.New(s))
		}
		if events[0].Event.Percentage == 100 {
			return newResponse(nil)
		}
		time.Sleep(defaultPollInterval)
	}
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
