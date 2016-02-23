package main

import (
	"errors"
	"flag"
	"fmt"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/utils/res"
	"os"
	"text/tabwriter"
	"text/template"

	"github.com/hashicorp/go-multierror"

	"golang.org/x/net/context"
)

func init() {
	Resources.Register(instanceResource)
}

var instanceResource = &res.Resource{
	Name:        "instance",
	Description: "Manage instances.",
	Commands: map[string]res.Command{
		"list":   new(instanceList),
		"delete": new(instanceDelete),
	},
}

// instanceList implements a list command
type instanceList struct {
	template string
	hostname string
	env      string
	id       int
	vlan     int
	entries  bool
}

func (*instanceList) Name() string {
	return "list"
}

func (cmd *instanceList) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.template, "t", "", "Applies given text/template to slice of datacenters.")
	f.StringVar(&cmd.hostname, "hostname", "", "Filters instances by hostname.")
	f.StringVar(&cmd.env, "env", "", "Filters instances by environment.")
	f.IntVar(&cmd.id, "id", 0, "Filters instances by id.")
	f.BoolVar(&cmd.entries, "entries", false, "Lists entries only.")
	f.IntVar(&cmd.vlan, "vlan", 0, "List instances for the given vlan.")
}

func (cmd *instanceList) Run(ctx context.Context) error {
	instances, err := cmd.list()
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

func (cmd *instanceList) list() (interface{}, error) {
	f := &sl.Filter{
		Hostname: cmd.hostname,
		ID:       cmd.id,
	}
	if cmd.env != "" {
		f.Tags = sl.Tags{
			"koding-env": cmd.env,
		}
	}
	if cmd.vlan != 0 {
		i, err := client.InstancesInVlan(cmd.vlan)
		if err != nil {
			return nil, err
		}

		i.Filter(f)
		if err := i.Err(); err != nil {
			return nil, err
		}
		return i, nil
	}
	if cmd.entries {
		return client.InstanceEntriesByFilter(f)
	}
	return client.InstancesByFilter(f)
}

func printInstances(v interface{}) error {
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 8, 1, '\t', 0)
	switch instances := v.(type) {
	case sl.Instances:
		fmt.Fprintln(w, "ID\tDatacenter\tHostname\tTags")
		for _, i := range instances {
			fmt.Fprintf(w, "%d\t%s\t%s\t%s\n", i.ID, i.Datacenter.Name, i.Hostname, i.Tags)
		}
	case sl.InstanceEntries:
		fmt.Fprintln(w, "ID\tHostname\tTags")
		for _, i := range instances {
			fmt.Fprintf(w, "%d\t%s\t%s\n", i.ID, i.Hostname, i.Tags)
		}
	default:
		return fmt.Errorf("unknown instances type to print: %T", v)
	}
	return w.Flush()
}

type instanceDelete struct {
	list instanceList
	dry  bool
}

func (cmd *instanceDelete) Name() string {
	return "delete"
}

func (cmd *instanceDelete) RegisterFlags(f *flag.FlagSet) {
	f.StringVar(&cmd.list.hostname, "hostname", "", "Filters instances by hostname.")
	f.StringVar(&cmd.list.env, "env", "", "Filters instances by environment.")
	f.IntVar(&cmd.list.id, "id", 0, "Filters instances by id.")
	f.BoolVar(&cmd.dry, "dry-run", false, "Dry run.")
	cmd.list.entries = true
}

func (cmd *instanceDelete) Valid() error {
	if cmd.list.id == 0 && (cmd.list.env == "" || cmd.list.env == "prod") && cmd.list.hostname == "" {
		return errors.New("refusing to delete all instances unconditionally")
	}
	return nil
}

func (cmd *instanceDelete) ids() ([]int, error) {
	if cmd.list.id != 0 {
		return []int{cmd.list.id}, nil
	}
	v, err := cmd.list.list()
	if err != nil {
		return nil, err
	}
	entries := v.(sl.InstanceEntries)
	ids := make([]int, len(entries))
	for i, e := range entries {
		ids[i] = e.ID
	}
	return ids, nil
}

func (cmd *instanceDelete) Run(ctx context.Context) error {
	if cmd.list.hostname == "" && cmd.list.id == 0 {
		return errors.New("denying delete of all instances")
	}
	ids, err := cmd.ids()
	if err != nil {
		return err
	}
	if cmd.dry {
		fmt.Println("Going to delete instances:", ids)
		return nil
	}
	var errs multierror.Error
	for _, id := range ids {
		fmt.Println("Deleting instance:", id)
		if err := client.DeleteInstance(id); err != nil {
			errs.Errors = append(errs.Errors, err)
		}
	}
	if len(errs.Errors) == 0 {
		fmt.Printf("Done deleting %d instances\n", len(ids))
		return nil
	}
	return &errs
}
