// Package res provides functionality for creating handlers for subcommands
// of subcommands. Such top-level subcommand is called a resource.
// Typical cli packages does not allow for creating nested subcommands,
// this package is a helper which fills the gap. Comes with out-of-the-box
// integration with the mitchellh/cli package.
package res

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/tabwriter"

	"github.com/mitchellh/cli"
	"golang.org/x/net/context"
)

// Validator validates arguments after parsing flags and before
// running the command.
type Validator interface {
	Valid() error
}

// Command represents a single action on a resource.
type Command interface {
	Name() string
	RegisterFlags(*flag.FlagSet)
	Run(context.Context) error
}

var _ cli.Command = (*Resource)(nil)

// ContextFunc creates a context for the subcommands from the command line
// arguments.
type ContextFunc func(args []string) context.Context

// Resource represents a single named resource.
type Resource struct {
	Name        string
	Description string
	Commands    map[string]Command
	ContextFunc ContextFunc
}

var _ cli.Command = (*ResourceTree)(nil)

// ResourceTree represents resources and their actions (commands).
type ResourceTree struct {
	name string
	tree map[string]*Resource
}

// New gives new context tree for the given name.
//
// If name is empty, the command named is inferred from os.Args[0].
func New(name string) *ResourceTree {
	rt := &ResourceTree{
		name: name,
		tree: make(map[string]*Resource),
	}
	if rt.name == "" {
		rt.name = filepath.Base(os.Args[0])
	}
	return rt
}

// Main executes a command by parsing the args, looking up the resource
// and the requested command.
func (rt *ResourceTree) Main(args []string) error {
	var res string
	if len(args) == 0 || ishelp(args[0]) {
		fmt.Fprintln(os.Stderr, rt.Help())
		return nil
	}

	for len(args) > 0 {
		res, args = args[0], args[1:]
		if !strings.HasPrefix(res, "-") {
			break
		}
	}
	resource, ok := rt.tree[res]
	if !ok {
		return fmt.Errorf("resource %q not found; see '%s -help' for details", res, rt.name)
	}

	return resource.Main(args)
}

// Run is a wrapper for the Main method that implements the cli.Command
// interface.
func (rt *ResourceTree) Run(args []string) int {
	if err := rt.Main(args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	return 0
}

// Help returns a help text.
func (rt *ResourceTree) Help() string {
	var buf bytes.Buffer
	fmt.Fprintf(&buf, "Usage: %s <resource> <command> [ARGS...]\n\n", rt.name)
	fmt.Fprintf(&buf, "Available resources:\n\n")
	w := tabwriter.NewWriter(&buf, 0, 8, 0, '\t', 0)
	for _, res := range rt.sortedResources() {
		fmt.Fprintf(&buf, "\t%s\t%s\n", res.Name, res.Description)
	}
	w.Flush()
	return buf.String()
}

// Synopsis returns a description for the resource tree.
func (rt *ResourceTree) Synopsis() string {
	return fmt.Sprintf("Manages the %s resources.", rt.name)
}

// CommandFactory method selector is used for providing cli.CommandFactory
// value.
func (rt *ResourceTree) CommandFactory() (cli.Command, error) {
	return rt, nil
}

// Register adds a resource.
func (rt *ResourceTree) Register(res *Resource) {
	rt.tree[res.Name] = res
}

// sortedResources gives a list of resources sorted by name.
func (rt *ResourceTree) sortedResources() []*Resource {
	var resources []*Resource
	for _, res := range rt.tree {
		resources = append(resources, res)
	}
	sort.Sort(resByName(resources))
	return resources
}

// Help returns a help text.
func (res *Resource) Help() string {
	var buf bytes.Buffer
	fmt.Fprintf(&buf, "Usage: ... %s <command> [ARGS...]\n\n", res.Name)
	fmt.Fprintf(&buf, "Available commands:\n\n")
	w := tabwriter.NewWriter(&buf, 0, 8, 0, '\t', 0)
	for _, cmd := range res.sortedCommands() {
		fmt.Fprintf(&buf, "\t%s\t%s\n", cmd.Name(), description(cmd))
	}
	w.Flush()
	return buf.String()
}

// Synopsis returns description of the resource.
func (res *Resource) Synopsis() string {
	return res.Description
}

// CommandFactory method selector is used for providing cli.CommandFactory
// value.
func (res *Resource) CommandFactory() (cli.Command, error) {
	return res, nil
}

// Main executes the given resource.
func (res *Resource) Main(args []string) error {
	var cmd string
	if len(args) == 0 || ishelp(args[0]) {
		fmt.Fprintln(os.Stderr, res.Help())
		return nil
	}
	for len(args) > 0 {
		cmd, args = args[0], args[1:]
		if !strings.HasPrefix(cmd, "-") {
			break
		}
	}
	command, ok := res.Commands[cmd]
	if !ok {
		return fmt.Errorf("command %[1]q for %[2]q resource not found; see '..."+
			" %[2]s -help' for details", cmd, res.Name)
	}

	flagsName := fmt.Sprintf("... %s %s", res.Name, cmd)
	flags := flag.NewFlagSet(flagsName, flag.ContinueOnError)
	command.RegisterFlags(flags)

	err := flags.Parse(args)
	if err == flag.ErrHelp {
		return nil
	}
	if err != nil {
		return err
	}

	if v, ok := command.(Validator); ok {
		if err := v.Valid(); err != nil {
			return err
		}
	}

	if res.ContextFunc != nil {
		return command.Run(res.ContextFunc(args))
	}

	return command.Run(context.Background())
}

// Run is a wrapper for the Main method which implements the cli.Command interface.
func (res *Resource) Run(args []string) int {
	if err := res.Main(args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 1
	}
	return 0
}

// sortedCommands gives a list of commands sorted by name.
func (res *Resource) sortedCommands() []Command {
	var commands []Command
	for _, cmd := range res.Commands {
		commands = append(commands, cmd)
	}
	sort.Sort(cmdByName(commands))
	return commands
}

// description builds a description text for the given command.
func description(cmd Command) string {
	var buf bytes.Buffer
	flags := flag.NewFlagSet(cmd.Name(), 0)
	cmd.RegisterFlags(flags)
	flags.VisitAll(func(f *flag.Flag) {
		fmt.Fprintf(&buf, "-%s <%T> ", f.Name, f.Value.(flag.Getter).Get())
	})
	return strings.TrimSpace(buf.String())
}

func ishelp(s string) bool {
	switch s {
	case "-h", "-help", "--help", "help":
		return true
	default:
		return false
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
