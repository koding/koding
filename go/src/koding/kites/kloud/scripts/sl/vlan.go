package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
	"text/template"

	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/utils/res"

	datatypes "github.com/maximilien/softlayer-go/data_types"
	"golang.org/x/net/context"
)

func init() {
	Resources.Register(vlanResource)
}

var vlanResource = &res.Resource{
	Name:        "vlan",
	Description: "Manage vlans.",
	Commands: map[string]res.Command{
		"list": new(vlanList),
		"edit": new(vlanEdit),
		"init": new(vlanInit),
	},
}

// vlanList implements a list command
type vlanList struct {
	template string
	id       int
}

func (*vlanList) Name() string {
	return "list"
}

func (cmd *vlanList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.template, "t", "", "Applies given text/template to slice of datacenters.")
	f.IntVar(&cmd.id, "id", 0, "Prints VLAN given by the ID.")
}

func (cmd *vlanList) Run(ctx context.Context) error {
	f := &sl.Filter{
		ID: cmd.id,
	}
	vlans, err := client.VlansByFilter(f)
	if err != nil {
		return err
	}
	switch {
	case cmd.template != "":
		t, err := template.New("list").Funcs(funcs).Parse(cmd.template)
		if err != nil {
			fmt.Fprintf(os.Stderr, "sl: failed to parse the filter: %s\n\n", err)
			break
		}
		return t.Execute(os.Stdout, vlans)
	}
	printVlans(vlans)
	return nil
}

func printVlans(vlans sl.VLANs) {
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tInternal ID\tTotal\tAvailable\tInstances\tDatacenter\tTags")
	for _, v := range vlans {
		fmt.Fprintf(w, "%d\t%d\t%d\t%d\t%d\t%s\t%s\n", v.ID, v.InternalID, v.Subnet.Total,
			v.Subnet.Available, v.InstanceCount, v.Subnet.Datacenter.Name, v.Tags)
	}
	w.Flush()
}

// vlanEdit implements an edit command
type vlanEdit struct {
	id   int
	tags string
}

func (*vlanEdit) Name() string {
	return "edit"
}

func (cmd *vlanEdit) RegisterFlags(f *flag.FlagSet) {
	f.IntVar(&cmd.id, "id", 0, "Vlan ID to set tags for.")
	f.StringVar(&cmd.tags, "tags", "", "Comma-separated key=value list of tags to set.")
}

func (cmd *vlanEdit) Valid() error {
	if cmd.id == 0 {
		return errors.New("empty value for -id flag")
	}
	return nil
}

func (cmd *vlanEdit) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}

	tags := sl.NewTags(strings.Split(cmd.tags, ","))
	return client.VlanSetTags(cmd.id, tags)
}

// vlanInit implements the an init command
type vlanInit struct {
	id       int
	capacity int
	env      string
}

func (*vlanInit) Name() string {
	return "init"
}

func (cmd *vlanInit) Valid() error {
	if cmd.id == 0 {
		return errors.New("empty value for -id flag")
	}
	if cmd.env == "" {
		return errors.New("empty value for -env flag")
	}
	return nil
}

func (cmd *vlanInit) RegisterFlags(f *flag.FlagSet) {
	f.IntVar(&cmd.id, "id", 0, "Vlan ID to init.")
	f.IntVar(&cmd.capacity, "cap", 0, "Vlan instance capacity.")
	f.StringVar(&cmd.env, "env", "", "Koding environment to init the Vlan for.")
}

func (cmd *vlanInit) Run(ctx context.Context) error {
	if err := cmd.Valid(); err != nil {
		return err
	}

	// TODO(rjeczalik): add sl.VlansByID
	vlans, err := client.VlansByFilter(&sl.Filter{ID: cmd.id})
	if err != nil {
		return err
	}
	if len(vlans) != 1 {
		return fmt.Errorf("want 1 vlan, got %d: %+v", len(vlans), vlans)
	}
	vlan := vlans[0]

	// If VLAN has one attached instance to it and the instance is removed,
	// the VLAN is removed as well. That's why we're adding dummy instance
	// to persist the VLAN as reference-counting is race-prone in
	// systems with eventual consistency.
	if vlan.InstanceCount == 0 {
		// TODO(rjeczalik): add instance creation API

		instance := datatypes.SoftLayer_Virtual_Guest_Template{
			Hostname:          "vlanguard",
			Domain:            "koding.io",
			StartCpus:         1,
			MaxMemory:         1024,
			HourlyBillingFlag: true,
			LocalDiskFlag:     true,
			Datacenter: datatypes.Datacenter{
				Name: vlan.Subnet.Datacenter.Name,
			},
			PrimaryBackendNetworkComponent: &datatypes.PrimaryBackendNetworkComponent{
				NetworkVlan: datatypes.NetworkVlan{
					Id: cmd.id,
				},
			},
			OperatingSystemReferenceCode: "UBUNTU_LATEST",
		}

		svc, err := client.GetSoftLayer_Virtual_Guest_Service()
		if err != nil {
			return err
		}

		fmt.Printf("Creating vlanguard instance for vlan id=%d\n", cmd.id)

		if _, err = svc.CreateObject(instance); err != nil {
			return err
		}
	}

	tags := vlan.Tags
	tags["koding-env"] = cmd.env
	if cmd.capacity > 0 {
		// Softlayer has no mean to discover VLAN capacity, as the subnets
		// are being added on demand. However the IBM guys said e.g.
		// the capacity for VLAN used for testing is 250 instances and
		// each VLAN shouldn't have more instances attached...
		tags["koding-vlan-cap"] = strconv.Itoa(cmd.capacity)
	}

	return client.VlanSetTags(vlan.ID, tags)
}
