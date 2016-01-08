package main

import (
	"flag"
	"fmt"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/utils/res"
	"os"
	"text/tabwriter"
	"text/template"

	"golang.org/x/net/context"
)

func init() {
	Resources.Register(instanceResource)
}

var instanceResource = &res.Resource{
	Name:        "instance",
	Description: "Manage instances.",
	Commands: map[string]res.Command{
		"list": new(instanceList),
	},
}

// instanceList implements a list command
type instanceList struct {
	template string
}

func (*instanceList) Name() string {
	return "list"
}

func (cmd *instanceList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.template, "t", "", "Applies given text/template to slice of datacenters.")
}

func (cmd *instanceList) Run(ctx context.Context) error {
	instances, err := client.InstancesByFilter(nil)
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
		return t.Execute(os.Stdout, instances)
	}
	printInstances(instances)
	return nil
}

func printInstances(instances sl.Instances) {
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tGlobalID\tDomain\tCreate date\tDatacenter")
	for _, i := range instances {
		fmt.Fprintf(w, "%d\t%s\t%s\t%s\t%s\n", i.ID, i.GlobalID, i.Domain,
			i.CreateDate, i.Datacenter.Name)
	}
	w.Flush()
}
