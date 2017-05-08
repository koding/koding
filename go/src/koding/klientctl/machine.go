package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"text/tabwriter"
	"time"

	"koding/klient/machine/mount"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/machine"
	"koding/klientctl/endpoint/team"

	"github.com/codegangsta/cli"
	humanize "github.com/dustin/go-humanize"
	"github.com/koding/logging"
)

// MachineListCommand returns list of remote machines belonging to the user or
// that can be accessed by her.
func MachineListCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// List command doesn't support identifiers.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}
	if err := identifiersLimit(idents, "machine", 0, 0); err != nil {
		return 1, err
	}

	opts := &machine.ListOptions{
		Log: log.New("machine:list"),
	}

	infos, err := machine.List(opts)
	if err != nil {
		return 1, err
	}

	if t := team.Used(); t.Valid() == nil {
		all := infos
		infos = infos[:0]

		for _, i := range all {
			if i.Team == t.Name {
				infos = append(infos, i)
			}
		}
	}

	if c.Bool("json") {
		printJSON(infos)
		return 0, nil
	}

	tabListFormatter(os.Stdout, infos)
	return 0, nil
}

// MachineSSHCommand allows to SSH into remote machine.
func MachineSSHCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// SSH command must have only one identifier.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}
	if err := identifiersLimit(idents, "machine", 1, 1); err != nil {
		return 1, err
	}

	opts := &machine.SSHOptions{
		Identifier: idents[0],
		Username:   c.String("username"),
		Log:        log.New("machine:ssh"),
	}

	if err := machine.SSH(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

// MachineMountCommand allows to create mount between remote and local machines.
func MachineMountCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	defer fixDescription("Mount remote folder to a local directory.")()
	// Mount command has two identifiers - remote machine:path and local path.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}
	if len(idents) == 0 {
		return 0, cli.ShowSubcommandHelp(c)
	}
	if err := identifiersLimit(idents, "argument", 1, 2); err != nil {
		return 1, err
	}
	ident, remotePath, path, err := mountExport(idents)
	if err != nil {
		return 1, err
	}

	opts := &machine.MountOptions{
		Identifier: ident,
		Path:       path,
		RemotePath: remotePath,
		Log:        log.New("machine:mount"),
	}

	if err := machine.Mount(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

// MachineListMountCommand lists available mounts.
func MachineListMountCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// Mount list command doesn't need identifiers.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}
	if err := identifiersLimit(idents, "mount", 0, 0); err != nil {
		return 1, err
	}

	opts := &machine.ListMountOptions{
		MountID: c.String("filter"),
		Log:     log.New("machine:mount:list"),
	}

	mounts, err := machine.ListMount(opts)
	if err != nil {
		return 1, err
	}

	if c.Bool("json") {
		printJSON(mounts)
		return 0, nil
	}

	tabListMountFormatter(os.Stdout, mounts)
	return 0, nil
}

// MachineUmountCommand removes the mount.
func MachineUmountCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// Umount command needs exactly one identifier. Either mount ID or
	// mount local path.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}

	all := c.Bool("all")
	if err := identifiersLimit(idents, "mount", 1, -1); !all && err != nil {
		return 1, err
	}

	opts := &machine.UmountOptions{
		Identifiers: idents,
		Force:       c.Bool("force"),
		All:         all,
		Log:         log.New("machine:umount"),
	}

	if err := machine.Umount(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

// MachineExecCommand runs a command in a started machine.
func MachineExecCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	if c.NArg() < 2 {
		cli.ShowCommandHelp(c, "exec")
		return 1, nil
	}

	done := make(chan int, 1)

	opts := &machine.ExecOptions{
		Cmd:  c.Args()[1],
		Args: c.Args()[2:],
		Stdout: func(line string) {
			fmt.Println(line)
		},
		Stderr: func(line string) {
			fmt.Fprintln(os.Stderr, line)
		},
		Exit: func(exit int) {
			done <- exit
			close(done)
		},
	}

	if s := c.Args()[0]; strings.HasPrefix(s, "@") {
		opts.MachineID = s[1:]
	} else {
		if !filepath.IsAbs(s) {
			var err error
			if s, err = filepath.Abs(s); err != nil {
				return 1, err
			}
		}

		opts.Path = s
	}

	pid, err := machine.Exec(opts)
	if err != nil {
		return 1, err
	}

	ctlcli.CloseOnExit(ctlcli.CloseFunc(func() error {
		select {
		case <-done:
			return nil
		default:
			return machine.Kill(&machine.KillOptions{
				MachineID: opts.MachineID,
				Path:      opts.Path,
				PID:       pid,
			})
		}
	}))

	return <-done, nil
}

// MachineCpCommand copies file(s) from one machine to another.
func MachineCpCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}

	if len(idents) == 0 {
		return 0, cli.ShowSubcommandHelp(c)
	}
	if err := identifiersLimit(idents, "argument", 2, 2); err != nil {
		return 1, err
	}
	download, ident, source, dest, err := cpAddress(idents)
	if err != nil {
		return 1, err
	}

	opts := &machine.CpOptions{
		Download:        download,
		Identifier:      ident,
		SourcePath:      source,
		DestinationPath: dest,
		Log:             log.New("machine:cp"),
	}

	if err := machine.Cp(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

// MachineInspectMountCommand allows to inspect internal mount status.
func MachineInspectMountCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// Machine inspect command needs exactly one identifier. Either mount ID or
	// mount local path.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}
	if err := identifiersLimit(idents, "mount", 1, 1); err != nil {
		return 1, err
	}

	// Enable sync option when there is none set explicitly. Tree may be too
	// large to show it implicitly.
	isSync, isTree := c.Bool("sync"), c.Bool("tree")
	if !isSync && !isTree {
		isSync = true
	}

	opts := &machine.InspectMountOptions{
		Identifier: idents[0],
		Sync:       isSync,
		Tree:       isTree,
		Log:        log.New("machine:inspect"),
	}

	records, err := machine.InspectMount(opts)
	if err != nil {
		return 1, err
	}

	printJSON(records)

	return 0, nil
}

// MachineStart turns a vm on.
func MachineStart(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	if err := machineCommand(c, machine.Start); err != nil {
		return 1, err
	}

	return 0, nil
}

// MachineStop turns a vm off.
func MachineStop(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	if err := machineCommand(c, machine.Stop); err != nil {
		return 1, err
	}

	return 0, nil
}

// MachineConfigSet sets key=value pair for a machine.
func MachineConfigSet(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	ident := c.Args().Get(0)
	key := c.Args().Get(1)
	value := c.Args().Get(2)

	switch {
	case ident == "":
		return 1, errors.New("machine identifier is empty or missing")
	case key == "":
		return 1, errors.New("configuration key is empty or missing")
	case value == "":
		return 1, errors.New("configuration value is empty or missing")
	}

	if err := machine.Set(ident, key, value); err != nil {
		return 1, err
	}

	return 0, nil
}

// MachineCondifShow displays machine's key=value pairs.
func MachineConfigShow(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	ident := c.Args().Get(0)
	json := c.Bool("json")

	if ident == "" {
		return 1, errors.New("machine identifier is empty or missing")
	}

	conf, err := machine.Show(ident)
	if err != nil {
		return 1, err
	}

	if json {
		printJSON(conf)
	} else {
		printKeyVal(conf)
	}

	return 0, nil
}

func machineCommand(c *cli.Context, fn func(string) (string, error)) error {
	ident := c.Args().Get(0)
	json := c.Bool("json")

	if ident == "" {
		return errors.New("machine identifier is empty or missing")
	}

	event, err := fn(ident)
	if err != nil {
		return err
	}

	for e := range machine.Wait(event) {
		if e.Error != nil {
			err = e.Error
		}

		if json {
			printJSON(e)
		} else {
			fmt.Printf("[%d%%] %s\n", e.Event.Percentage, e.Event.Message)
		}
	}

	return err
}

// getIdentifiers extracts identifiers and validate provided arguments.
// TODO(ppknap): other CLI libraries like Cobra have this out of the box.
func getIdentifiers(c *cli.Context) (idents []string, err error) {
	unknown := make([]string, 0)
	for _, arg := range c.Args() {
		if strings.HasPrefix(arg, "-") {
			unknown = append(unknown, arg)
			continue
		}

		idents = append(idents, arg)
	}

	if len(unknown) > 0 {
		plural := ""
		if len(unknown) > 1 {
			plural = "s"
		}

		return nil, fmt.Errorf("unrecognized argument%s: %s", plural, strings.Join(unknown, ", "))
	}

	return idents, nil
}

// identifiersLimit checks if the number of identifiers is in specified limits.
// If max is -1, there are no limits for the maximum number of identifiers.
func identifiersLimit(idents []string, kind string, min, max int) error {
	switch l := len(idents); {
	case l > 0 && min == 0:
		return fmt.Errorf("this command does not use %s identifiers", kind)
	case l < min:
		return fmt.Errorf("required at least %d %ss", min, kind)
	case max != -1 && l > max:
		return fmt.Errorf("too many %ss: %s", kind, strings.Join(idents, ", "))
	}
	return nil
}

// mountAddress checks if provided identifiers are valid from the mount
// perspective. The identifiers should satisfy the following format:
//
//  (ID|Alias|IP):remote_directory/path local_directory/path
//
func mountAddress(idents []string) (ident, remotePath, path string, err error) {
	if len(idents) != 2 {
		return "", "", "", fmt.Errorf("invalid number of arguments: %s", strings.Join(idents, ", "))
	}

	remote := strings.Split(idents[0], ":")
	if len(remote) != 2 {
		return "", "", "", fmt.Errorf("invalid remote address format: %s", idents[0])
	}

	if path, err = filepath.Abs(idents[1]); err != nil {
		return "", "", "", fmt.Errorf("invalid format of local path %q: %s", idents[1], err)
	}

	return remote[0], remote[1], path, nil
}

// mountExport checks if provided identifiers are valid from the mount
// perspective. The identifiers should satisfy the following format:
//
//   (ID|Alias|IP)[:remote_directory/path] [local_directory/path]
//
func mountExport(idents []string) (ident, remotePath, path string, err error) {
	if len(idents) != 1 && len(idents) != 2 {
		return "", "", "", fmt.Errorf("invalid number of arguments: %s", strings.Join(idents, ", "))
	}

	ident = idents[0]

	if i := strings.IndexRune(ident, ':'); i != -1 {
		ident, remotePath = ident[:i], ident[i+1:]
	}

	if len(idents) == 2 {
		if path, err = filepath.Abs(idents[1]); err != nil {
			return "", "", "", fmt.Errorf("invalid format of local path %q: %s", idents[1], err)
		}
	}

	return
}

// cpAddress checks if provided identifiers are valid from the cp command
// perspective. The identifiers should satisfy the following format:
//
//  [(ID|Alias|IP):]source_directory/path [(ID|Alias|IP):]remote_directory/path
//
func cpAddress(idents []string) (download bool, ident, source, dest string, err error) {
	if len(idents) != 2 {
		err = fmt.Errorf("invalid number of arguments: %s", strings.Join(idents, ", "))
		return
	}

	srcs, dsts := strings.Split(idents[0], ":"), strings.Split(idents[1], ":")
	switch srcl, dstl := len(srcs), len(dsts); {
	case srcl == 1 && dstl == 1 || srcl >= 2 && dstl >= 2:
		err = fmt.Errorf("invalid address format: %s %s", idents[0], idents[1])
		return
	case srcl == 2 && dstl == 1:
		if dest, err = filepath.Abs(dsts[0]); err != nil {
			err = fmt.Errorf("invalid format of local path %q: %s", dsts[0], err)
			return
		}
		ident, source = srcs[0], srcs[1]
		download = true
	case srcl == 1 && dstl == 2: // upload.
		if source, err = filepath.Abs(srcs[0]); err != nil {
			err = fmt.Errorf("invalid format of local path %q: %s", srcs[0], err)
			return
		}
		ident, dest = dsts[0], dsts[1]
	}

	return
}

func tabListFormatter(w io.Writer, infos []*machine.Info) {
	now := time.Now()
	tw := tabwriter.NewWriter(w, 2, 0, 2, ' ', 0)

	fmt.Fprintf(tw, "ID\tALIAS\tTEAM\tSTACK\tPROVIDER\tLABEL\tOWNER\tAGE\tIP\tSTATUS\n")
	for _, info := range infos {
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			info.ID,
			info.Alias,
			dashIfEmpty(info.Team),
			dashIfEmpty(info.Stack),
			dashIfEmpty(info.Provider),
			info.Label,
			info.Owner,
			machine.ShortDuration(info.CreatedAt, now),
			info.IP,
			machine.PrettyStatus(info.Status, now),
		)
	}
	tw.Flush()
}

func tabListMountFormatter(w io.Writer, mounts map[string][]mount.Info) {
	tw := tabwriter.NewWriter(w, 2, 0, 2, ' ', 0)

	// TODO: keep the mounts list sorted.
	fmt.Fprintf(tw, "ID\tMACHINE\tMOUNT\tFILES\tQUEUED\tSYNCING\tSIZE\n")
	for alias, infos := range mounts {
		for _, info := range infos {
			sign := info.Syncing
			fmt.Fprintf(tw, "%s\t%s\t%s\t%s/%s\t%s\t%s\t%s/%s\n",
				info.ID,
				alias,
				info.Mount,
				dashIfNegative(sign, info.Count),
				dashIfNegative(sign, info.CountAll),
				dashIfNegative(sign, info.Queued),
				errorIfNegative(info.Syncing),
				dashIfNegative(sign, humanize.IBytes(uint64(info.DiskSize))),
				dashIfNegative(sign, humanize.IBytes(uint64(info.DiskSizeAll))),
			)
		}
	}
	tw.Flush()
}

func printJSON(v interface{}) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")
	enc.Encode(v)
}

func errorIfNegative(val int) string {
	if val < 0 {
		return "err"
	}

	return strconv.Itoa(val)
}

func dashIfNegative(sign int, val interface{}) string {
	if sign < 0 {
		return "-"
	}

	return fmt.Sprint(val)
}

func dashIfEmpty(val string) string {
	if val == "" {
		return "-"
	}

	return val
}
