package main

import (
	"flag"
	"fmt"
	"os"
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
	fmt.Fprintln(w, "ID\tName\tTotal\tAvailable\tDatacenter")
	for _, v := range vlans {
		fmt.Fprintf(w, "%d\t%s\t%d\t%d\t%s\n", v.ID, v.Name, v.Subnet.Total,
			v.Subnet.Available, v.Subnet.Datacenter.Name)
	}
	w.Flush()
}
