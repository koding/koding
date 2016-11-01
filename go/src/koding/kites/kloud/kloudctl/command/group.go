package command

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strings"
	"sync"
	"text/tabwriter"
	"time"

	"koding/db/mongodb/modelhelper"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"koding/db/models"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/utils/res"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/hashicorp/go-multierror"
	"github.com/koding/kite"
	"github.com/koding/logging"
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
					"list":      NewGroupList(),
					"create":    NewGroupCreate(),
					"stack":     NewGroupStack(),
					"delete":    NewGroupDelete(),
					"fixdomain": NewGroupFixDomain(),
					"clean":     NewGroupClean(),
					"seal":      NewGroupSeal(),
				},
			},
		}
		return f, nil
	}
}

func (g *Group) Action(args []string) error {
	k, err := kloudClient()
	if err != nil {
		return err
	}
	ctx := context.Background()
	ctx = context.WithValue(ctx, kiteKey, k)
	ctx = context.WithValue(ctx, softlayerKey, newSoftlayer())
	g.Resource.ContextFunc = func([]string) context.Context { return ctx }
	return g.Resource.Main(args)
}

type GroupSeal struct {
	*groupVMCache
	ips *groupValues

	jobs     int
	kloudpem string
	script   string

	scriptraw string
}

func NewGroupSeal() *GroupSeal {
	return &GroupSeal{
		ips:          &groupValues{flag: "ips"},
		groupVMCache: newGroupVMCache(),
	}
}

func (*GroupSeal) Name() string {
	return "seal"
}

func (cmd *GroupSeal) RegisterFlags(f *flag.FlagSet) {
	cmd.ips.RegisterFlags(f)
	cmd.groupVMCache.RegisterFlags(f)

	f.StringVar(&cmd.kloudpem, "kloud-pem", os.Getenv("KLOUD_PEM"), "Path to the kloud_rsa.pem private key.")
	f.StringVar(&cmd.script, "script", "", "Script to execute on user vms.")
	f.IntVar(&cmd.jobs, "j", 8, "Number of parallel job executions.")
}

func (cmd *GroupSeal) Valid() error {
	if err := cmd.ips.Valid(); err != nil {
		return err
	}

	// we have no ips, we need to read them from softlayer by looking up
	// usernames
	if len(cmd.ips.values) == 0 {
		if err := cmd.groupVMCache.Valid(); err != nil {
			return err
		}
	}

	if cmd.kloudpem == "" {
		return errors.New("invalid empty value provided for -kloud-pem flag")
	}

	if cmd.script == "" {
		return errors.New("invalid empty value provided for -script flag")
	}

	p, err := ioutil.ReadFile(cmd.script)
	if err != nil {
		return err
	}

	cmd.scriptraw = string(p)

	return nil
}

func (cmd *GroupSeal) Run(ctx context.Context) error {
	ips := make(chan string)
	var wg sync.WaitGroup

	merr := new(multierror.Error)
	var mu sync.Mutex

	if len(cmd.ips.values) != 0 {
		go func() {
			for _, ip := range cmd.ips.values {
				ips <- ip
			}

			close(ips)
		}()
	} else {
		go func() {
			for _, user := range cmd.groupVMCache.values {
				ips <- cmd.vms[user].IPAddress
			}

			close(ips)
		}()
	}

	for range make([]struct{}, cmd.jobs) {
		wg.Add(1)
		go func() {
			defer wg.Done()

			for ip := range ips {
				args := []string{
					"-oUserKnownHostsFile=/dev/null",
					"-oStrictHostKeyChecking=no",
					"-oConnectTimeout=30",
					"-oConnectionAttempts=2",
					"-i", cmd.kloudpem,
					"root@" + ip,
					"cat > script.sh && chmod +x script.sh && ./script.sh && rm -f script.sh",
				}

				var errBuf bytes.Buffer
				var outBuf bytes.Buffer

				c := exec.Command("ssh", args...)
				c.Stdin = strings.NewReader(cmd.scriptraw)
				c.Stderr = &errBuf
				c.Stdout = &outBuf

				errch := make(chan error, 1)

				go func() {
					errch <- c.Run()
				}()

				var err error

				// when one timeout is not enough
				select {
				case err = <-errch:
				case <-time.After(5 * time.Minute):
					err = errors.New("ssh has timed out after 5m")
				}

				if err != nil {
					err = fmt.Errorf("failed running script for ip=%q: %s (stderr=%q)", ip, err, &errBuf)
					mu.Lock()
					merr = multierror.Append(merr, err)
					mu.Unlock()
				} else {
					DefaultUi.Info(fmt.Sprintf("success running script for ip=%q: %s", ip, &outBuf))
				}
			}
		}()
	}

	wg.Wait()

	return merr.ErrorOrNil()
}

type groupVMCache struct {
	*groupValues

	vmcache string
	env     string

	vms    map[string]*sl.Instance
	users  map[string]struct{}
	client *sl.Softlayer
}

func newGroupVMCache() *groupVMCache {
	return &groupVMCache{
		groupValues: &groupValues{flag: "users"},
		vms:         make(map[string]*sl.Instance),
		client:      newSoftlayer(),
	}
}

func (*groupVMCache) Name() string {
	return "vm-cache"
}

func (cmd *groupVMCache) RegisterFlags(f *flag.FlagSet) {
	cmd.groupValues.RegisterFlags(f)

	home := "."
	if u, err := user.Current(); err == nil {
		home = u.HomeDir
	}

	f.StringVar(&cmd.vmcache, "vm-cache", filepath.Join(home, ".vm-cache.json"), "Cache file for fetches vms details.")
	f.StringVar(&cmd.env, "env", "production", "VLAN environment value for koding-env tag.")
}

func (cmd *groupVMCache) Valid() error {
	if err := cmd.groupValues.Valid(); err != nil {
		return err
	}

	if cmd.vmcache == "" {
		return errors.New("invalid empty value provided for vm-cache flag")
	}

	if len(cmd.values) == 0 {
		return errors.New("invalid empty value provided for -users flag")
	}

	cmd.users = make(map[string]struct{}, len(cmd.values))
	for _, user := range cmd.values {
		cmd.users[strings.ToLower(user)] = struct{}{}
	}

	f, err := os.Open(cmd.vmcache)
	if err == nil {
		err = json.NewDecoder(f).Decode(&cmd.vms)

		if err != nil {
			DefaultUi.Error(fmt.Sprintf("unable to read %q: %s", cmd.vmcache, err))
		}

		f.Close()
	}

	err = cmd.verifyCache()

	if err == nil {
		return nil
	}

	DefaultUi.Info(fmt.Sprintf("building vm cache in %q due to: %s", cmd.vmcache, err))

	vlans, err := cmd.client.VlansByFilter(cmd.filter())
	if err != nil {
		return err
	}

	cmd.vms = make(map[string]*sl.Instance)

	DefaultUi.Info(fmt.Sprintf("processing %d vlans...", len(vlans)))

	for _, vlan := range vlans {
		vms, err := cmd.client.InstancesInVlan(vlan.ID)
		if sl.IsNotFound(err) {
			continue
		}
		if err != nil {
			return err
		}

		DefaultUi.Info(fmt.Sprintf("processing %d vms...", len(vms)))

		for _, vm := range vms {
			key := strings.ToLower(vm.Hostname)

			if key == "vlanguard" {
				key = fmt.Sprintf("vlanguard-%d", vm.ID)
				cmd.vms[key] = vm
				continue
			}

			if _, ok := cmd.users[key]; !ok {
				continue
			}

			if oldVM, ok := cmd.vms[key]; ok && oldVM.ID != vm.ID {
				DefaultUi.Warn(fmt.Sprintf("multiple vms for user %q: %d, %d", key, oldVM.ID, vm.ID))
				continue
			}

			cmd.vms[key] = vm
		}
	}

	DefaultUi.Info(fmt.Sprintf("fetched %d vms", len(cmd.vms)))

	if err := cmd.verifyCache(); err != nil {
		return fmt.Errorf("failed to build cache: %s", err)
	}

	f, err = os.Create(cmd.vmcache)
	if err != nil {
		DefaultUi.Error(fmt.Sprintf("unable to dump vm cache to %q: %s", cmd.vmcache, err))
		return nil
	}

	err = nonil(json.NewEncoder(f).Encode(cmd.vms), f.Sync(), f.Close())

	if err != nil {
		DefaultUi.Error(fmt.Sprintf("unable to dump vm cache to %q: %s", cmd.vmcache, nonil(err, os.Remove(f.Name()))))
	} else {
		DefaultUi.Info(fmt.Sprintf("vm-cache for %d instances dumped to %q", len(cmd.vms), cmd.vmcache))
	}

	return nil
}

func (cmd *groupVMCache) verifyCache() error {
	for user := range cmd.users {
		if _, ok := cmd.vms[user]; !ok {
			return fmt.Errorf("vm for user %q not present in cache, invalidating", user)
		}
	}

	return nil
}

func (cmd *groupVMCache) vlanguard(vm *sl.Instance) string {
	for _, vlan := range vm.VLANs {
		key := fmt.Sprintf("vlanguard-%d", vlan.ID)
		if _, ok := cmd.vms[key]; ok {
			return key
		}
	}

	return ""
}

func (cmd *groupVMCache) filter() *sl.Filter {
	if cmd.env == "" {
		return nil
	}
	return &sl.Filter{
		Tags: sl.Tags{
			"koding-env": cmd.env,
		},
	}
}

type GroupClean struct {
	vlan       int
	datacenter string
	env        string
	dry        bool

	uCache map[string]*models.User
	mCache map[string][]*models.Machine
}

func NewGroupClean() *GroupClean {
	return &GroupClean{
		uCache: make(map[string]*models.User),
		mCache: make(map[string][]*models.Machine),
	}
}

func (*GroupClean) Name() string {
	return "clean"
}

func (cmd *GroupClean) RegisterFlags(f *flag.FlagSet) {
	f.IntVar(&cmd.vlan, "vlan", 0, "Vlan ID which to clean the vlans for.")
	f.StringVar(&cmd.datacenter, "dc", "", "Datacenter name.")
	f.StringVar(&cmd.env, "env", "production", "Environment name.")
	f.BoolVar(&cmd.dry, "dry", false, "Dry run.")
}

func (cmd *GroupClean) Run(ctx context.Context) error {
	modelhelper.Initialize(envMongoURL())
	defer modelhelper.Close()

	var vlans []int

	_, client := fromContext(ctx)

	if cmd.vlan != 0 {
		vlans = append(vlans, cmd.vlan)
	}

	f := &sl.Filter{
		Datacenter: cmd.datacenter,
		Tags: sl.Tags{
			"koding-env": cmd.env,
		},
	}

	v, err := client.VlansByFilter(f)
	if err != nil {
		return err
	}

	for _, v := range v {
		vlans = append(vlans, v.ID)
	}

	merr := new(multierror.Error)
	toclean := make(map[int]*sl.Instance)

	DefaultUi.Info("verifying local references...")

	for _, vlan := range vlans {
		vms, err := client.InstancesInVlan(vlan)
		if err != nil {
			err = fmt.Errorf("failed to get instance list for vlan=%d: %s", vlan, err)
			merr = multierror.Append(merr, err)
			continue
		}

		DefaultUi.Info(fmt.Sprintf("processing %d instances for vlan=%d", len(vms), vlan))

		for _, vm := range vms {
			user := vm.Tags["koding-user"]
			if user == "" {
				user = vm.Hostname
			}

			if user == "vlanguard" {
				continue
			}
			if user == "" {
				merr = multierror.Append(merr, fmt.Errorf("no user found for instanceID=%d", vm.ID))
				continue
			}

			m, err := cmd.machines(user)
			if err != nil {
				err = fmt.Errorf("unable to get jMachines for user=%q, instanceID=%d: %s", user, vm.ID, err)
				merr = multierror.Append(merr, err)
				continue
			}

			// Decide if the machine needs to be cleaned.
			//
			// A machine needs to be cleaned if nothing from DB references it.
			// In particular, if:
			//
			//   - machine's public IP matches jMachines.ipAddress, or
			//   - machine's koding-domain tag matches jMachines.domain, or
			//   - machine's koding-machineid tag matches jMachines.ObjectId, or
			//   - machine's ID matches jMachines.meta.id
			//
			// Then we consider this machine as active, thus we do not clean it.
			// If the machine in fact should be cleaned (false negative),
			// then kloud just leaked this machine by not cleaning references.
			// To inspect reasons why machines were not cleaned, use -dry flag.

			clean, dryInfo := cmd.doClean(vm, m)
			if dryInfo != nil {
				merr = multierror.Append(merr, fmt.Errorf("not cleaning %d for user %s: %s", vm.ID, user, dryInfo))
			}

			if clean {
				DefaultUi.Info(fmt.Sprintf("found unreferenced %d", vm.ID))

				toclean[vm.ID] = vm
			}
		}
	}

	DefaultUi.Info("verifying global references...")

	// We checked already that vm is not referenced locally (by a user owning it),
	// ensure it's not referenced globally (by any user).
	for id, vm := range toclean {
		for user, m := range cmd.mCache {
			clean, dryInfo := cmd.doClean(vm, m)

			if !clean {
				DefaultUi.Error(fmt.Sprintf("instance %d is referenced by a different user %q: %s", id, user, dryInfo))

				delete(toclean, id)
			}
		}
	}

	if cmd.dry {
		DefaultUi.Info(merr.Error())
		DefaultUi.Info(fmt.Sprintf("\ngoing to clean the following machines (%d): %v", len(toclean), toclean))

		return nil
	}

	for id := range toclean {
		DefaultUi.Info(fmt.Sprintf("deleting %d", id))

		err := client.DeleteInstance(id)
		if err != nil {
			merr = multierror.Append(merr, err)
		}
	}

	return merr.ErrorOrNil()
}

func (cmd *GroupClean) doClean(vm *sl.Instance, machines []*models.Machine) (clean bool, dryInfo error) {
	clean = true

	for _, m := range machines {
		if m.IpAddress != "" && m.IpAddress == vm.IPAddress {
			if cmd.dry {
				dryInfo = errors.New("IP address matches")
			}
			clean = false
			break
		}

		if m.Domain != "" && m.Domain == vm.Tags["koding-domain"] {
			if cmd.dry {
				dryInfo = errors.New("domain matches")
			}
			clean = false
			break
		}

		if id := m.ObjectId.Hex(); id != "" && id == vm.Tags["koding-machineid"] {
			if cmd.dry {
				dryInfo = errors.New("jMachines.ObjectId matches")
			}
			clean = false
			break
		}

		if id, ok := m.Meta["id"].(int); ok && id != 0 && id == vm.ID {
			if cmd.dry {
				dryInfo = errors.New("jMachines.meta.id matches")
			}
			clean = false
			break
		}
	}

	return clean, dryInfo
}

func (cmd *GroupClean) machines(user string) ([]*models.Machine, error) {
	m, ok := cmd.mCache[user]
	if ok {
		return m, nil
	}

	u, err := cmd.user(user)
	if err != nil {
		return nil, err
	}

	m, err = modelhelper.GetMachinesByProvider(u.ObjectId, "softlayer")
	if err != nil {
		return nil, err
	}

	cmd.mCache[user] = m
	return m, nil
}

func (cmd *GroupClean) user(user string) (*models.User, error) {
	u, ok := cmd.uCache[user]
	if ok {
		return u, nil
	}

	u, err := modelhelper.GetUser(user)
	if err != nil {
		return nil, err
	}

	cmd.uCache[user] = u
	return u, nil
}

type GroupFixDomain struct {
	*groupValues

	machine string
	access  string
	secret  string
	env     string
	dry     bool

	dns *dnsclient.Route53
}

func NewGroupFixDomain() *GroupFixDomain {
	return &GroupFixDomain{
		groupValues: &groupValues{flag: "users"},
	}
}

func (cmd *GroupFixDomain) Name() string {
	return "fixdomain"
}

func (cmd *GroupFixDomain) Valid() error {
	if err := cmd.groupValues.Valid(); err != nil {
		return err
	}

	if len(cmd.values) == 0 {
		return errors.New("no usernames provided for -users flag")
	}

	if cmd.machine == "" {
		return errors.New("no value provided for -machine flag")
	}

	if cmd.env == "" {
		return errors.New("no value provided for -env flag")
	}

	zone := dnsZones[cmd.env]
	if zone == "" {
		return errors.New("invalid value provided for -env flag")
	}

	if cmd.access == "" {
		return errors.New("no value provided for -access flag")
	}

	if cmd.secret == "" {
		return errors.New("no value provided for -secret flag")
	}

	dnsOpts := &dnsclient.Options{
		Creds:      credentials.NewStaticCredentials(cmd.access, cmd.secret, ""),
		HostedZone: zone,
		Log:        logging.NewCustom("dns", flagDebug),
	}

	dns, err := dnsclient.NewRoute53Client(dnsOpts)
	if err != nil {
		return err
	}

	cmd.dns = dns

	return nil
}

func nonempty(s ...string) string {
	for _, s := range s {
		if s != "" {
			return s
		}
	}
	return ""
}

func route53defaults() (string, string) {
	access := nonempty(os.Getenv("ROUTE53_ACCESS_KEY"), os.Getenv("AWS_ACCESS_KEY"))
	secret := nonempty(os.Getenv("ROUTE53_SECRET_KEY"), os.Getenv("AWS_SECRET_KEY"))
	return access, secret
}

func (cmd *GroupFixDomain) RegisterFlags(f *flag.FlagSet) {
	cmd.groupValues.RegisterFlags(f)

	access, secret := route53defaults()

	f.BoolVar(&cmd.dry, "dry", false, "Dry run.")
	f.StringVar(&cmd.machine, "machine", "", "Machine slug/label name.")
	f.StringVar(&cmd.env, "env", os.Getenv("KITE_ENVIRONMENT"), "Environment name.")
	f.StringVar(&cmd.access, "access", access, "Route53 access key.")
	f.StringVar(&cmd.secret, "secret", secret, "Route53 secret key.")
}

func min(i, j int) int {
	if i < j {
		return i
	}
	return j
}

func (cmd *GroupFixDomain) Run(ctx context.Context) error {
	modelhelper.Initialize(envMongoURL())
	defer modelhelper.Close()

	merr := new(multierror.Error)
	users := cmd.values

	for len(users) > 0 {
		var batch []string
		var records []*dnsclient.Record
		var ids []bson.ObjectId
		n := min(len(users), 100)
		batch, users = users[:n], users[n:]

		DefaultUi.Info(fmt.Sprintf("checking %d records...", n))

		for _, user := range batch {
			rec, id, err := cmd.fixDomain(user)
			if err != nil {
				merr = multierror.Append(merr, err)
				continue
			}

			if cmd.dry {
				if rec == nil {
					merr = multierror.Append(merr, fmt.Errorf("domain for %q is ok", user))
				} else {
					merr = multierror.Append(merr, fmt.Errorf("domain for %q is going to be upserted without -dry: %q", user, rec.Name))
				}

				continue
			}

			if rec == nil {
				continue
			}

			records = append(records, rec)
			ids = append(ids, id)
		}

		if len(records) == 0 {
			continue
		}

		DefaultUi.Info(fmt.Sprintf("going to upsert %d domains", len(records)))

		// upsert domains
		if err := cmd.dns.UpsertRecords(records...); err != nil {
			merr = multierror.Append(merr, err)
		}

		// update domains
		if err := cmd.update(records, ids); err != nil {
			merr = multierror.Append(merr, err)
		}
	}

	return merr.ErrorOrNil()
}

func (cmd *GroupFixDomain) fixDomain(user string) (*dnsclient.Record, bson.ObjectId, error) {
	u, err := modelhelper.GetUser(user)
	if err != nil {
		return nil, "", err
	}

	m, err := modelhelper.GetMachineBySlug(u.ObjectId, cmd.machine)
	if err != nil {
		return nil, "", fmt.Errorf("fixing failed for %q user: %s", user, err)
	}

	if m.IpAddress == "" {
		return nil, "", errors.New("no ip address found for: " + user)
	}

	base := dnsZones[cmd.env]

	if strings.HasSuffix(m.Domain, base) {
		return nil, "", nil
	}

	if cmd.dry && m.State() != machinestate.Running {
		DefaultUi.Warn(fmt.Sprintf("machine %q of user %q is not running (%s)",
			m.ObjectId.Hex(), user, m.State()))
	}

	s := m.Domain
	if i := strings.Index(s, user); i != -1 {
		s = s[i+len(user):] + "." + base
	}

	return &dnsclient.Record{
		Name: s,
		IP:   m.IpAddress,
		Type: "A",
		TTL:  300,
	}, m.ObjectId, nil
}

func (cmd *GroupFixDomain) update(records []*dnsclient.Record, ids []bson.ObjectId) error {
	merr := new(multierror.Error)

	for i, rec := range records {
		err := modelhelper.UpdateMachine(ids[i], bson.M{"domain": rec.Name})
		if err != nil {
			err = fmt.Errorf("failed updating %q domain to %q: %s", ids[i].Hex(), rec.Name, err)
			merr = multierror.Append(merr, err)
		}
	}

	return merr.ErrorOrNil()
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
	f.StringVar(&cmd.group, "group", "koding", "Name of the instance group to list.")
	f.StringVar(&cmd.env, "env", "dev", "Kloud environment.")
	f.StringVar(&cmd.tags, "tags", "", "Tags to filter instances.")
	f.StringVar(&cmd.hostname, "hostname", "", "Hostname to filter instances.")
	f.BoolVar(&cmd.entries, "entries", false, "Whether the lookup only entries as oppose to full details.")
}

func (cmd *GroupList) Run(ctx context.Context) error {
	modelhelper.Initialize(envMongoURL())
	defer modelhelper.Close()

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

type groupValues struct {
	flag string

	valuesraw string
	values    []string
}

func (gu *groupValues) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&gu.valuesraw, gu.flag, "", fmt.Sprintf("Comma-separated list of %s (can't be used with -n).", gu.flag))
}

func (gu *groupValues) Valid() error {
	uniq := make(map[string]struct{})

	for _, user := range strings.Split(gu.valuesraw, ",") {
		uniq[strings.TrimSpace(user)] = struct{}{}
	}

	// For "-users -" flag we read usernames from stdin.
	if _, ok := uniq["-"]; ok {
		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			uniq[strings.TrimSpace(scanner.Text())] = struct{}{}
		}
		if err := scanner.Err(); err != nil {
			return err
		}
	}

	delete(uniq, "")
	delete(uniq, "-")

	if len(uniq) == 0 {
		return nil
	}

	gu.values = make([]string, 0, len(uniq))

	for user := range uniq {
		gu.values = append(gu.values, user)
	}

	return nil
}

// GroupCreate implements the "kloudctl group create" subcommand.
type GroupCreate struct {
	*GroupThrottler
	*groupValues

	dry       bool
	stack     bool
	file      string
	count     int
	eventer   bool
	pullmongo time.Duration
}

func NewGroupCreate() *GroupCreate {
	cmd := &GroupCreate{
		groupValues: &groupValues{flag: "users"},
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
	cmd.groupValues.RegisterFlags(f)

	f.StringVar(&cmd.file, "f", "", "JSON-encoded Machine specification file.")
	f.IntVar(&cmd.count, "n", 1, "Number of machines to be created.")
	f.BoolVar(&cmd.dry, "dry", false, "Dry run, tells the status of machines for the users.")
	f.DurationVar(&cmd.pullmongo, "pullmongo", 20*time.Minute, "Timeout for the build, pulls jMachine.status.state for status.")
	f.BoolVar(&cmd.eventer, "eventer", false, "Use kloud eventer instead of pulling MongoDB.")
}

func (cmd *GroupCreate) Valid() error {
	if err := cmd.groupValues.Valid(); err != nil {
		return err
	}

	if len(cmd.values) != 0 && cmd.count > 1 {
		return errors.New("the -users and -n flags can't be used together")
	}

	if cmd.pullmongo == 0 && !cmd.eventer {
		return errors.New("invalid value for -pullmongo flag")
	}

	if !cmd.eventer {
		cmd.GroupThrottler.Wait = cmd.waitFunc(cmd.pullmongo)
	}

	return nil
}

func queryState(id string) (machinestate.State, error) {
	var state struct {
		Status struct {
			State string `bson:"state,omitempty"`
		} `bson:"status,omitempty"`
	}

	query := func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&state)
	}

	err := modelhelper.Mongo.Run(modelhelper.MachinesColl, query)
	if err != nil {
		return 0, err
	}

	return machinestate.States[state.Status.State], nil
}

func (cmd *GroupCreate) waitFunc(timeout time.Duration) WaitFunc {
	const maxFailures = 5

	return func(id string) error {
		var building bool
		initialTimeout := time.After(1 * time.Minute)
		overallTimeout := time.After(timeout)

		failureNum := 0
		lastState := machinestate.NotInitialized

		DefaultUi.Info(fmt.Sprintf("watching status for %q", id))

		for {
			select {
			case <-initialTimeout:
				if !building {
					return fmt.Errorf("waiting for %q to become building has timed out, aborting", id)
				}
			case <-overallTimeout:
				return fmt.Errorf("giving up waiting for %q to be running; last state %q", id, lastState)
			default:
				state, err := queryState(id)
				if err != nil {
					failureNum++
					if failureNum > maxFailures {
						return fmt.Errorf("querying for state of %q failed more than %d times"+
							" in a row, aborting: %s", id, maxFailures, err)
					}

					time.Sleep(15 * time.Second)
					continue
				}

				DefaultUi.Info(fmt.Sprintf("%s: status for %q: %s", time.Now(), id, state))

				failureNum = 0
				lastState = state

				switch state {
				case machinestate.NotInitialized, machinestate.Unknown, machinestate.Stopped, machinestate.Stopping,
					machinestate.Terminating, machinestate.Terminated, machinestate.Rebooting:
					if building {
						return fmt.Errorf("machine %q was building, transitioned to %q, aborting", id, state)
					}
				case machinestate.Building, machinestate.Starting:
					building = true
				case machinestate.Running:
					return nil
				}

				time.Sleep(15 * time.Second)
			}
		}
	}
}

func (cmd *GroupCreate) Run(ctx context.Context) (err error) {
	modelhelper.Initialize(envMongoURL())
	defer modelhelper.Close()

	var spec *MachineSpec
	if !cmd.dry {
		spec, err = ParseMachineSpec(cmd.file)
	} else {
		spec = &MachineSpec{
			Machine: models.Machine{
				Provider: "softlayer",
				Users: []models.MachineUser{{
					Username: "softlayer",
				}},
				Slug: "softlayer-vm-0",
			},
		}
	}
	if err != nil {
		return err
	}

	var specs []*MachineSpec
	if len(cmd.values) != 0 {
		specs, err = cmd.multipleUserSpecs(spec)
	} else {
		specs, err = cmd.multipleMachineSpecs(spec)
	}
	if len(specs) == 0 {
		if err != nil {
			DefaultUi.Warn(err.Error())
		}
		return errors.New("nothing to build")
	}

	if err != nil {
		DefaultUi.Warn(err.Error())
	}

	items := make([]Item, len(specs))
	for i, spec := range specs {
		items[i] = spec
	}

	if e := cmd.RunItems(ctx, items); e != nil {
		return multierror.Append(err, e).ErrorOrNil()
	}

	return err
}

func specSlice(spec *MachineSpec, n int) []*MachineSpec {
	specs := make([]*MachineSpec, n)
	for i := range specs {
		specs[i] = spec.Copy()
	}
	return specs
}

func (cmd *GroupCreate) multipleUserSpecs(spec *MachineSpec) ([]*MachineSpec, error) {
	specs := specSlice(spec, len(cmd.values))
	var okspecs []*MachineSpec

	merr := new(multierror.Error)

	DefaultUi.Info("Preparing jMachine documents for users...")

	for i, spec := range specs {
		spec.User = models.User{
			Name: cmd.values[i],
		}

		err := spec.BuildMachine(false)
		if err == ErrRebuild {
			if cmd.dry {
				merr = multierror.Append(merr, fmt.Errorf("jMachine status for %q: this is going to be rebuild without -dry", spec.Username()))
			} else {
				okspecs = append(okspecs, spec)
			}

			continue
		}
		if cmd.dry && err == nil {
			merr = multierror.Append(merr, fmt.Errorf("jMachine status for %q: this is going to be build without -dry", spec.Username()))
			continue
		}
		if err != nil {
			merr = multierror.Append(merr, fmt.Errorf("jMachine status for %q: %s", spec.Username(), err))
			continue
		}

		okspecs = append(okspecs, spec)
	}

	DefaultUi.Info(fmt.Sprintf("%d to be machines built", len(okspecs)))

	return okspecs, merr.ErrorOrNil()
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
	if err := spec.InsertMachine(); err != nil {
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

	var result stack.ControlResult
	return resp.Unmarshal(&result)
}

// GroupStack implements the "kloudctl group toggle" subcommand.
type GroupStack struct {
	*groupValues

	rm          bool
	groupSlug   string
	machineSlug string
	baseID      string
	jobs        int
}

func NewGroupStack() *GroupStack {
	return &GroupStack{
		groupValues: &groupValues{flag: "users"},
	}
}

func (*GroupStack) Name() string {
	return "stack"
}

func (cmd *GroupStack) RegisterFlags(f *flag.FlagSet) {
	cmd.groupValues.RegisterFlags(f)

	f.StringVar(&cmd.machineSlug, "machine", "", "Machine slug.")
	f.StringVar(&cmd.groupSlug, "group", "koding", "Group slug.")
	f.BoolVar(&cmd.rm, "rm", false, "Remove machine from stack and template.")
	f.StringVar(&cmd.baseID, "base-id", "53fe557af052f8e9435a04fa", "Base Stack ID for new jComputeStack documents.")
	f.IntVar(&cmd.jobs, "j", 1, "Number of concurrent jobs.")
}

func (cmd *GroupStack) Valid() error {
	if cmd.machineSlug == "" {
		return errors.New("invalid empty value for -machine flag")
	}
	if err := cmd.groupValues.Valid(); err != nil {
		return err
	}
	if len(cmd.groupValues.values) == 0 {
		return errors.New("invalid empty value for -users flag")
	}
	return nil
}

func (cmd *GroupStack) Run(ctx context.Context) error {
	modelhelper.Initialize(envMongoURL())
	defer modelhelper.Close()

	var mu sync.Mutex
	var wg sync.WaitGroup
	merr := new(multierror.Error)
	jobs := make(chan string)

	go func() {
		for _, username := range cmd.groupValues.values {
			jobs <- username
		}
		close(jobs)
	}()

	DefaultUi.Info(fmt.Sprintf("processing %d users...", len(cmd.groupValues.values)))

	for range make([]struct{}, cmd.jobs) {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for username := range jobs {
				sd, err := cmd.details(username)
				if err != nil {
					merr = multierror.Append(merr, err)
					continue
				}

				if cmd.rm {
					err = modelhelper.RemoveFromStack(sd)
				} else {
					err = modelhelper.AddToStack(sd)
				}
				if err != nil {
					DefaultUi.Warn(fmt.Sprintf("processing %q user stack failed: %s", username, err))

					mu.Lock()
					merr = multierror.Append(merr, err)
					mu.Unlock()
				} else {
					DefaultUi.Warn(fmt.Sprintf("processed %q user stack", username))
				}
			}
		}()
	}

	wg.Wait()

	return merr.ErrorOrNil()
}

func (cmd *GroupStack) details(username string) (*modelhelper.StackDetails, error) {
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return nil, fmt.Errorf("unable to find a user %q: %s", username, err)
	}

	group, err := modelhelper.GetGroup(cmd.groupSlug)
	if err != nil {
		return nil, fmt.Errorf("unable to find a group %q: %s", cmd.groupSlug, err)
	}

	machine, err := modelhelper.GetMachineBySlug(user.ObjectId, cmd.machineSlug)
	if err != nil {
		return nil, fmt.Errorf("unable to find a machine slug=%q, userID=%q: %s", cmd.machineSlug, user.ObjectId.Hex(), err)
	}

	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, fmt.Errorf("unable to find an account for %q: %s", username, err)
	}

	sd := &modelhelper.StackDetails{
		UserID:    user.ObjectId,
		AccountID: account.Id,
		GroupID:   group.Id,

		UserName:  user.Name,
		GroupSlug: group.Slug,

		MachineID: machine.ObjectId,
		BaseID:    bson.ObjectIdHex(cmd.baseID),
	}

	return sd, nil
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
	modelhelper.Initialize(envMongoURL())
	defer modelhelper.Close()

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

	var result stack.ControlResult
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
