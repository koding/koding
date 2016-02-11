package command

import (
	"bufio"
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
					"list":   NewGroupList(),
					"create": NewGroupCreate(),
					"stack":  NewGroupStack(),
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
	group    string
	env      string
	tags     string
	hostname string
	entries  bool
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
	f.StringVar(&cmd.hostname, "hostname", "", "Hostname to filter instances.")
	f.BoolVar(&cmd.entries, "entries", false, "Whether the lookup only entries as oppose to full details.")
}

func (cmd *GroupList) Run(ctx context.Context) error {
	if cmd.entries {
		return cmd.printEntries(ctx)
	}
	return cmd.printInstances(ctx)
}

func (cmd *GroupList) printInstances(ctx context.Context) error {
	instances, err := cmd.listInstances(ctx, cmd.filter())
	if err != nil {
		return err
	}
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 16, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tSoftlayerID\tUser\tDatacener\tTags")
	for _, i := range instances {
		fmt.Fprintf(w, "%s\t%d\t%s\t%s\t%s\n", i.Tags["koding-machineid"], i.ID, i.Tags["koding-user"],
			i.Datacenter.Name, i.Tags)
	}
	w.Flush()
	return nil
}

func (cmd *GroupList) printEntries(ctx context.Context) error {
	entries, err := cmd.listEntries(ctx, cmd.filter())
	if err != nil {
		return err
	}
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 16, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tSoftlayerID\tUser\tHostname\tTags")
	for _, e := range entries {
		fmt.Fprintf(w, "%s\t%d\t%s\t%s\t%s\n", e.Tags["koding-machineid"], e.ID, e.Tags["koding-user"],
			e.Hostname, e.Tags)
	}
	w.Flush()
	return nil
}

func (cmd *GroupList) filter() *sl.Filter {
	f := &sl.Filter{
		Hostname: cmd.hostname,
		Tags:     sl.Tags{},
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
			panic(err)
		}
		f.Tags["koding-groupid"] = group.Id.Hex()
	}
	return f
}

func (cmd *GroupList) listInstances(ctx context.Context, f *sl.Filter) (sl.Instances, error) {
	_, c := fromContext(ctx)
	return c.InstancesByFilter(f)
}

func (cmd *GroupList) listEntries(ctx context.Context, f *sl.Filter) (sl.InstanceEntries, error) {
	_, c := fromContext(ctx)
	return c.InstanceEntriesByFilter(f)
}

type groupUsers struct {
	users     string
	usernames []string
}

func (gu *groupUsers) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&gu.users, "users", "", "Comma-separated list of usernames (can't be used with -n).")
}

func (gu *groupUsers) Valid() error {
	gu.usernames = strings.Split(gu.users, ",")

	// For "-users -" flag we read usernames from stdin.
	if len(gu.usernames) == 1 && gu.usernames[0] == "-" {
		gu.usernames = gu.usernames[:0]

		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			s := strings.TrimSpace(scanner.Text())
			if s != "" {
				gu.usernames = append(gu.usernames, s)
			}
		}
		if err := scanner.Err(); err != nil {
			return err
		}
	}

	return nil
}

// GroupCreate implements the "kloudctl group create" subcommand.
type GroupCreate struct {
	*GroupThrottler
	*groupUsers

	nostack bool
	file    string
	count   int
}

func NewGroupCreate() *GroupCreate {
	cmd := &GroupCreate{
		groupUsers: &groupUsers{},
	}
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
	cmd.groupUsers.RegisterFlags(f)

	f.StringVar(&cmd.file, "f", "", "JSON-encoded Machine specification file.")
	f.IntVar(&cmd.count, "n", 1, "Number of machines to be created.")
	f.BoolVar(&cmd.nostack, "nostack", false, "Do not show the vm in user stack.")
}

func (cmd *GroupCreate) Valid() error {
	if err := cmd.groupUsers.Valid(); err != nil {
		return err
	}

	if len(cmd.usernames) != 0 && cmd.count > 1 {
		return errors.New("the -users and -n flags can't be used together")
	}

	return nil
}

func (cmd *GroupCreate) Run(ctx context.Context) error {
	spec, err := ParseMachineSpec(cmd.file)
	if err != nil {
		return err
	}

	var specs []*MachineSpec
	if len(cmd.usernames) != 0 {
		specs, err = cmd.multipleUserSpecs(spec)
	} else {
		specs, err = cmd.multipleMachineSpecs(spec)
	}
	if err != nil {
		return err
	}

	items := make([]Item, len(specs))
	for i, spec := range specs {
		items[i] = spec
	}

	return cmd.RunItems(ctx, items)
}

func specSlice(spec *MachineSpec, n int) []*MachineSpec {
	specs := make([]*MachineSpec, n)
	for i := range specs {
		specs[i] = spec.Copy()
	}
	return specs
}

func (cmd *GroupCreate) multipleUserSpecs(spec *MachineSpec) ([]*MachineSpec, error) {
	specs := specSlice(spec, len(cmd.usernames))

	for i, spec := range specs {
		spec.User = models.User{
			Name: cmd.usernames[i],
		}

		if err := spec.BuildMachine(false); err != nil {
			return nil, fmt.Errorf("error building user and group for %q: %s", spec.User.Name, err)
		}
	}

	return specs, nil
}

func (cmd *GroupCreate) multipleMachineSpecs(spec *MachineSpec) ([]*MachineSpec, error) {
	if err := spec.BuildMachine(true); err != nil {
		return nil, err
	}

	specs := specSlice(spec, cmd.count)

	// Index the machines.
	if len(specs) > 1 {
		for _, spec := range specs {
			i := shortUID()
			spec.Machine.Slug = fmt.Sprintf("%s-%s", spec.Machine.Slug, i)
			spec.Machine.Label = fmt.Sprintf("%s-%s", spec.Machine.Label, i)
		}
	}

	return specs, nil
}

func (cmd *GroupCreate) build(ctx context.Context, item Item) error {
	spec := item.(*MachineSpec)
	k, _ := fromContext(ctx)
	if err := spec.InsertMachine(cmd.nostack); err != nil {
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

// GroupStack implements the "kloudctl group toggle" subcommand.
type GroupStack struct {
	*groupUsers

	rm          bool
	groupSlug   string
	machineSlug string
}

func NewGroupStack() *GroupStack {
	return &GroupStack{
		groupUsers: &groupUsers{},
	}
}

func (*GroupStack) Name() string {
	return "stack"
}

func (cmd *GroupStack) RegisterFlags(f *flag.FlagSet) {
	cmd.groupUsers.RegisterFlags(f)

	f.StringVar(&cmd.machineSlug, "machine", "", "Machine slug.")
	f.StringVar(&cmd.groupSlug, "group", "koding", "Group slug.")
	f.BoolVar(&cmd.rm, "rm", false, "Remove machine from stack and template.")
}

func (cmd *GroupStack) Valid() error {
	if cmd.machineSlug == "" {
		return errors.New("invalid empty value for -machine flag")
	}
	if err := cmd.groupUsers.Valid(); err != nil {
		return err
	}
	if len(cmd.groupUsers.usernames) == 0 {
		return errors.New("invalid empty value for -users flag")
	}
	return nil
}

func (cmd *GroupStack) Run(ctx context.Context) error {
	merr := new(multierror.Error)

	for _, username := range cmd.groupUsers.usernames {
		userID, groupID, machineID, err := cmd.details(username)
		if err != nil {
			merr = multierror.Append(merr, err)
			continue
		}

		if cmd.rm {
			err = modelhelper.RemoveFromStack(userID, groupID, machineID)
		} else {
			err = modelhelper.AddToStack(userID, groupID, machineID)
		}
		if err != nil {
			merr = multierror.Append(merr, err)
		}
	}

	return merr.ErrorOrNil()
}

func (cmd *GroupStack) details(username string) (userID, groupID, machineID bson.ObjectId, err error) {
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return "", "", "", errors.New("unable to find a user: " + err.Error())
	}

	group, err := modelhelper.GetGroup(cmd.groupSlug)
	if err != nil {
		return "", "", "", errors.New("unable to find a group: " + err.Error())
	}

	machine, err := modelhelper.GetMachineBySlug(user.ObjectId, cmd.machineSlug)
	if err != nil {
		return "", "", "", errors.New("unable to find a machine: " + err.Error())
	}

	return user.ObjectId, group.Id, machine.ObjectId, nil
}

// GroupDelete implememts the "kloudctl group delete" subcommand.
type GroupDelete struct {
	GroupList
	*GroupThrottler

	provider string
}

func NewGroupDelete() *GroupDelete {
	cmd := &GroupDelete{}
	cmd.GroupThrottler = &GroupThrottler{
		Name:    "destroy",
		Process: cmd.destroy,
	}
	return cmd
}

func (*GroupDelete) Name() string {
	return "delete"
}

func (cmd *GroupDelete) RegisterFlags(f *flag.FlagSet) {
	cmd.GroupList.RegisterFlags(f)
	cmd.GroupThrottler.RegisterFlags(f)

	f.StringVar(&cmd.provider, "provider", "softlayer", "Kloud provider name.")
}

func (cmd *GroupDelete) Run(ctx context.Context) error {
	entries, err := cmd.listEntries(ctx, cmd.filter())
	if err != nil {
		return err
	}
	items := make([]Item, len(entries))
	for i, entry := range entries {
		items[i] = &Instance{
			SoftlayerID: entry.ID,
			Domain:      entry.Tags["koding-domain"],
			Username:    entry.Tags["koding-user"],
		}
	}
	// TODO(rjeczalik): It's not possible to concurrently delete domains due to:
	//
	//   ERROR    could not delete domain "ukhscbd6fee9.kloudctl.dev.koding.io":
	//   PriorRequestNotComplete: The request was rejected because Route 53 was
	//   still processing a prior request.\n\tstatus code: 400, request id:
	//   c8248760-b2e5-11e5-9b7d-33010efc6afe"
	//
	cmd.GroupThrottler.throttle = 1
	return cmd.RunItems(ctx, items)
}

func (cmd *GroupDelete) destroy(ctx context.Context, item Item) error {
	instance := item.(*Instance)
	k, c := fromContext(ctx)

	var m models.Machine
	query := func(c *mgo.Collection) error {
		where := bson.M{
			"domain":         instance.Domain,
			"users.username": instance.Username,
		}
		return c.Find(where).One(&m)
	}

	err := modelhelper.Mongo.Run("jMachines", query)
	if err == mgo.ErrNotFound {
		return nonil(c.DeleteInstance(instance.SoftlayerID), ErrSkipWatch)
	}

	instance.MachineID = m.ObjectId.Hex()

	req := &KloudArgs{
		MachineId: instance.ID(),
		Provider:  cmd.provider,
	}
	resp, err := k.Tell("destroy", req)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	return resp.Unmarshal(&result)
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

func kiteFromContext(ctx context.Context) *kite.Client {
	return ctx.Value(kiteKey).(*kite.Client)
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
