package command

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"koding/db/models"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/utils/res"

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
					"list":   NewGroupList(),
					"create": NewGroupCreate(),
					"delete": NewGroupDelete(),
				},
			},
		}
		return f, nil
	}
}

func (g *Group) Action(args []string, k *kite.Client) error {
	ctx := context.Background()
	ctx = context.WithValue(ctx, kiteKey, k)
	ctx = context.WithValue(ctx, softlayerKey, newSoftlayer())
	modelhelper.Initialize(envMongoURL())
	defer modelhelper.Close()
	g.Resource.ContextFunc = func([]string) context.Context { return ctx }
	return g.Resource.Main(args)
}

type GroupList struct {
	group string
	env   string
	tags  string
}

func NewGroupList() *GroupList {
	return &GroupList{}
}

func (*GroupList) Name() string {
	return "list"
}

func (cmd *GroupList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.group, "group", "hackathon", "Name of the instance group to list.")
	f.StringVar(&cmd.env, "env", "dev", "Kloud environment.")
	f.StringVar(&cmd.tags, "tags", "", "Tags to filter instances.")
}

func (cmd *GroupList) Run(ctx context.Context) error {
	instances, err := cmd.listInstances(ctx)
	if err != nil {
		return err
	}
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 16, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tUser\tDatacener\tTags")
	for _, i := range instances {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", i.Tags["koding-machineid"], i.Tags["koding-user"],
			i.Datacenter.Name, i.Tags)
	}
	w.Flush()
	return nil
}

func (cmd *GroupList) listInstances(ctx context.Context) (sl.Instances, error) {
	_, c := fromContext(ctx)
	f := &sl.Filter{
		Tags: sl.Tags{},
	}
	if cmd.tags != "" {
		tags := sl.NewTags(strings.Split(cmd.tags, ","))
		for k, v := range tags {
			f.Tags[k] = v
		}
	}
	if cmd.env != "" {
		f.Tags["koding-env"] = cmd.env
	}
	if cmd.group != "" {
		var group models.Group
		query := func(c *mgo.Collection) error {
			return c.Find(bson.M{"slug": cmd.group}).One(&group)
		}
		if err := modelhelper.Mongo.Run("jGroups", query); err != nil {
			return nil, err
		}
		f.Tags["koding-groupid"] = group.Id.Hex()
	}
	return c.InstancesByFilter(f)
}

// GroupCreate implements the "kloudctl group create" subcommand.
type GroupCreate struct {
	*GroupThrottler

	file  string
	count int
}

func NewGroupCreate() *GroupCreate {
	cmd := &GroupCreate{}
	cmd.GroupThrottler = &GroupThrottler{
		Name:    "build",
		Process: cmd.build,
	}
	return cmd
}

func (*GroupCreate) Name() string {
	return "create"
}

func (cmd *GroupCreate) RegisterFlags(f *flag.FlagSet) {
	cmd.GroupThrottler.RegisterFlags(f)

	f.StringVar(&cmd.file, "f", "", "JSON-encoded Machine specification file.")
	f.IntVar(&cmd.count, "n", 1, "Number of machines to be created.")
}

func (cmd *GroupCreate) Run(ctx context.Context) error {
	spec, err := ParseMachineSpec(cmd.file)
	if err != nil {
		return err
	}
	if err := spec.BuildUserAndGroup(); err != nil {
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

	items := make([]Item, len(specs))
	for i, spec := range specs {
		items[i] = spec
	}

	return cmd.RunItems(ctx, items)
}

func (cmd *GroupCreate) build(ctx context.Context, item Item) error {
	spec := item.(*MachineSpec)
	k, _ := fromContext(ctx)
	if err := spec.BuildMachine(); err != nil {
		return err
	}

	buildReq := &KloudArgs{
		MachineId: spec.Machine.ObjectId.Hex(),
		Provider:  spec.Machine.Provider,
		Username:  spec.Username(),
	}
	resp, err := k.Tell("build", buildReq)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	return resp.Unmarshal(&result)
}

// GroupDelete implememts the "kloudctl group delete" subcommand.
type GroupDelete struct{}

func NewGroupDelete() *GroupDelete {
	return &GroupDelete{}
}

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

var softlayerKey struct {
	byte `key:"softlayer"`
}

func fromContext(ctx context.Context) (*kite.Client, *sl.Softlayer) {
	k := ctx.Value(kiteKey).(*kite.Client)
	c := ctx.Value(softlayerKey).(*sl.Softlayer)
	return k, c
}

func newSoftlayer() *sl.Softlayer {
	return sl.NewSoftlayer(
		os.Getenv("SOFTLAYER_USER_NAME"),
		os.Getenv("SOFTLAYER_API_KEY"),
	)
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
