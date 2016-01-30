package main

import (
	"errors"
	"flag"
	"fmt"
	"os"
	"strings"
	"text/tabwriter"
	"text/template"

	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/utils/res"

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
