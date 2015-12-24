package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"sort"
	"strings"
	"text/tabwriter"

	"koding/kites/kloud/api/sl"
)

var (
	username = os.Getenv("SOFTLAYER_USER_NAME")
	apiKey   = os.Getenv("SOFTLAYER_API_KEY")
)

// Main is used to globally register each Softlayer resources handler.
var Main = make(ResourceTree)

// Command represents a single action on a resource.
type Command interface {
	Name() string
	RegisterFlags(*flag.FlagSet)
	Run(*sl.Softlayer) error
}

// Resource represents a Softlayer resource.
type Resource struct {
	Name        string
	Description string
	Commands    map[string]Command
}

// ResourceTree represents resources and their actions (commands).
type ResourceTree map[string]*Resource

// Run executes a command on requested resource.
func (rt ResourceTree) Run(client *sl.Softlayer, args []string) error {
	var res, cmd string
	if len(args) == 0 || args[0] == "-help" {
		fmt.Fprintln(os.Stderr, rt.Usage())
		return nil
	}

	res, args = args[0], args[1:]
	if len(args) == 0 || args[0] == "-help" {
		fmt.Fprintln(os.Stderr, rt.ResourceUsage(res))
		return nil
	}

	cmd, args = args[0], args[1:]
	resource, ok := rt[res]
	if !ok {
		return fmt.Errorf("resource %q not found; see 'sl -help' for details", res)
	}

	command, ok := resource.Commands[cmd]
	if !ok {
		return fmt.Errorf("command %[1]q for %[2]q resource not found; see 'sl %[2]s -help' for details", cmd, res)
	}

	flags := flag.NewFlagSet("sl "+res+" "+cmd, flag.ContinueOnError)
	command.RegisterFlags(flags)

	err := flags.Parse(args)
	if err == flag.ErrHelp {
		return nil
	}
	if err != nil {
		return err
	}

	return command.Run(client)
}

// Register adds a resource.
func (rt ResourceTree) Register(res *Resource) {
	rt[res.Name] = res
}

// Usage returns a usage text.
func (rt ResourceTree) Usage() string {
	var buf bytes.Buffer
	fmt.Fprintln(&buf, "Usage: sl <resource> <command> [ARGS...]")
	fmt.Fprintln(&buf)
	fmt.Fprintln(&buf, "Available resources:")
	fmt.Fprintln(&buf)
	w := tabwriter.NewWriter(&buf, 0, 8, 0, '\t', 0)
	for _, res := range rt.Resources() {
		fmt.Fprintf(&buf, "\t%s\t%s\n", res.Name, res.Description)
	}
	w.Flush()
	return buf.String()
}

// ResourceUsage returns a usage text build for the given resource.
func (rt ResourceTree) ResourceUsage(res string) string {
	var buf bytes.Buffer
	fmt.Fprintf(&buf, "Usage: sl %s <command> [ARGS...]\n", res)
	fmt.Fprintln(&buf)
	fmt.Fprintln(&buf, "Available commands:")
	fmt.Fprintln(&buf)
	w := tabwriter.NewWriter(&buf, 0, 8, 0, '\t', 0)
	for _, cmd := range rt.ResourceCommands(res) {
		fmt.Fprintf(&buf, "\t%s\t%s\n", cmd.Name(), rt.Description(cmd))
	}
	w.Flush()
	return buf.String()
}

// Resources returns slice of Softlayer resources, sorted by name.
func (rt ResourceTree) Resources() []*Resource {
	var resources []*Resource
	for _, res := range rt {
		resources = append(resources, res)
	}
	sort.Sort(resByName(resources))
	return resources
}

// ResourceCommands returns a slice of commands for the given resource,
// sorted by name.
func (rt ResourceTree) ResourceCommands(res string) []Command {
	var commands []Command
	for _, cmd := range rt[res].Commands {
		commands = append(commands, cmd)
	}
	sort.Sort(cmdByName(commands))
	return commands
}

// Description builds a description text for the given command.
func (rt ResourceTree) Description(cmd Command) string {
	var buf bytes.Buffer
	flags := flag.NewFlagSet(cmd.Name(), 0)
	cmd.RegisterFlags(flags)
	flags.VisitAll(func(f *flag.Flag) {
		fmt.Fprintf(&buf, "-%s <%T> ", f.Name, f.Value.(flag.Getter).Get())
	})
	return strings.TrimSpace(buf.String())
}

func die(v interface{}) {
	fmt.Fprintln(os.Stderr, v)
	os.Exit(1)
}

func main() {
	if username == "" {
		die("SOFTLAYER_USER_NAME is not set")
	}
	if apiKey == "" {
		die("SOFTLAYER_API_KEY is not set")
	}
	client, err := sl.NewSoftlayer(username, apiKey)
	if err != nil {
		die(err)
	}
	if err = Main.Run(client, os.Args[1:]); err != nil {
		die(err)
	}
}

type resByName []*Resource

func (p resByName) Len() int           { return len(p) }
func (p resByName) Less(i, j int) bool { return p[i].Name < p[j].Name }
func (p resByName) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }

type cmdByName []Command

func (p cmdByName) Len() int           { return len(p) }
func (p cmdByName) Less(i, j int) bool { return p[i].Name() < p[j].Name() }
func (p cmdByName) Swap(i, j int)      { p[i], p[j] = p[j], p[i] }
