package main

import (
	"encoding/json"
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
	Resources.Register(datacenterResource)
}

var datacenterResource = &res.Resource{
	Name:        "datacenter",
	Description: "Manage datacenters.",
	Commands: map[string]res.Command{
		"list": new(datacenterList),
	},
}

// datacenterList implements a list command
type datacenterList struct {
	name     string
	template string
}

func (*datacenterList) Name() string {
	return "list"
}

var funcs = map[string]interface{}{
	"json": func(v interface{}) (string, error) {
		p, err := json.MarshalIndent(v, "", "\t")
		if err != nil {
			return "", err
		}
		return string(p), nil
	},
}

func (cmd *datacenterList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.name, "name", "", "Filters datacenters by given name.")
	f.StringVar(&cmd.template, "t", "", "Applies given text/template to slice of datacenters.")
}

func (cmd *datacenterList) Run(context.Context) error {
	f := &sl.Filter{
		Name: cmd.name,
	}
	datacenters, err := client.DatacentersByFilter(f)
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
		return t.Execute(os.Stdout, datacenters)
	}
	printDatacenters(datacenters)
	return nil
}

func printDatacenters(datacenters sl.Datacenters) {
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tName\tLong name\tStatus\tTimezone")
	for _, d := range datacenters {
		fmt.Fprintf(w, "%d\t%s\t%s\t%s\t%s\n", d.ID, d.Name, d.LongName,
			d.Status.Status, fmt.Sprintf("%s (%s)", d.Timezone.ShortName, d.Timezone.Offset))
	}
	w.Flush()
}
