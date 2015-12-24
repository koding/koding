package command

import (
	"errors"
	"flag"
	"fmt"
	"os"

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
	file  string
	count int
}

func (*GroupCreate) Name() string {
	return "create"
}

func (cmd *GroupCreate) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.file, "f", "", "JSON-encoded Machine specification file.")
	f.IntVar(&cmd.count, "n", 1, "Number of machines to be created.")
}

func (cmd *GroupCreate) Run(ctx context.Context) error {
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
		for i, spec := range specs {
			spec.Machine.Slug = fmt.Sprintf("%s-%d", spec.Machine.Slug, i)
			spec.Machine.Label = fmt.Sprintf("%s-%d", spec.Machine.Label, i)
		}
	}
	return cmd.createMachines(ctx, specs...)
}

func (cmd *GroupCreate) createMachines(ctx context.Context, specs ...*MachineSpec) error {
	errch := make(chan error, len(specs))
	for _, spec := range specs {
		go func(spec *MachineSpec) {
			resp, err := requestMachine(ctx, spec)
			if err != nil {
				errch <- fmt.Errorf("request %q machine failed: %s", spec.Machine.Label, err)
			} else {
				DefaultUi.Info(fmt.Sprintf("machine %q requested: eventID=%s",
					spec.Machine.Label, resp.EventId))
				errch <- nil
			}
		}(spec)
	}
	var errs *multierror.Error
	for range specs {
		if err := <-errch; err != nil {
			errs = multierror.Append(errs, err)
		}
	}
	return errs.ErrorOrNil()
}

func requestMachine(ctx context.Context, spec *MachineSpec) (*kloud.ControlResult, error) {
	k, db := fromContext(ctx)
	if err := spec.BuildMachine(db); err != nil {
		return nil, err
	}
	req := &KloudArgs{
		MachineId: spec.Machine.ObjectId.Hex(),
		Provider:  spec.Machine.Provider,
		Username:  spec.Username(),
	}
	resp, err := k.Tell("build", req)
	if err != nil {
		return nil, err
	}
	var result kloud.ControlResult
	if err = resp.Unmarshal(&result); err != nil {
		return nil, err
	}
	return &result, nil
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
