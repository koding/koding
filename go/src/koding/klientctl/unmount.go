package main

import (
	"errors"
	"fmt"
	"io"

	"koding/klient/remote/req"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/klient"
	"koding/klientctl/list"
	"koding/klientctl/metrics"
	"koding/klientctl/util"

	"github.com/koding/kite/dnode"

	"github.com/koding/logging"

	"github.com/koding/kite"
)

type UnmountOptions struct {
	// MountName is the identifier for the given mount.
	MountName string

	// Path is the mounted path. Attempted to be unmounted and removed if
	Path string

	// A collection of paths that we will never remove.
	NeverRemove []string
}

type UnmountCommand struct {
	Options UnmountOptions
	Stdout  io.Writer
	Stdin   io.Reader
	Log     logging.Logger

	// The klient instance this struct will use.
	Klient interface {
		RemoteList() (list.KiteInfos, error)
		GetClient() *kite.Client
		Tell(string, ...interface{}) (*dnode.Partial, error)
	}

	// The options to use if this struct needs to dial Klient.
	//
	// Note! These will be ignored if c.Klient is already defined before Run() is
	// called.
	KlientOptions klient.KlientOptions

	// the following vars exist primarily for mocking ability, and ensuring
	// an enclosed environment within the struct.

	// The ctlcli Helper. See the type docs for a better understanding of this.
	helper ctlcli.Helper

	// The HealthChecker we'll use if we suspect that there may be problems.
	healthChecker *HealthChecker

	// The fileRemover removes files, typically via os.Remove()
	fileRemover func(string) error

	// mountFinder is used to find the mount path by the name.
	mountFinder interface {
		FindMountedPathByName(name string) (string, error)
	}
}

// Help prints help to the caller.
func (c *UnmountCommand) Help() {
	if c.helper == nil {
		// Ugh, talk about a bad UX
		fmt.Fprintln(c.Stdout, "Error: Help was requested but mount has no helper.")
		return
	}

	c.helper(c.Stdout)
}

// printf is a helper function for printing to the internal writer.
func (c *UnmountCommand) printfln(f string, i ...interface{}) {
	if c.Stdout == nil {
		return
	}

	fmt.Fprintf(c.Stdout, f+"\n", i...)
}

// Run the Mount command
func (c *UnmountCommand) Run() (int, error) {
	if err := c.handleOptions(); err != nil {
		return 1, err
	}

	if err := c.setupKlient(); err != nil {
		c.printfln(c.healthChecker.CheckAllFailureOrMessagef(GenericInternalError))
		return 1, err
	}

	// Find the mount name and path
	if err := c.findMountAndPath(); err != nil {
		return 1, err
	}

	// unmount using mount name
	if err := c.Unmount(c.Options.MountName, c.Options.Path); err != nil {
		c.printfln(c.healthChecker.CheckAllFailureOrMessagef(FailedToUnmount))
		return 1, err
	}

	// remove the mount folder.
	//
	// Note that if there is an error, we still successfully unmounted - we just
	// failed to remove the folder. So go ahead and print success.
	err := c.removeMountFolder()

	// make sure to print success *after* removeMountFolder. Even though we're
	// ignoring removal errors, we don't want to print success and then a warning.
	c.printfln("Unmount complete.")

	return 0, err
}

// handleOptions deals with options, erroring if options are missing, etc.
func (c *UnmountCommand) handleOptions() error {
	if c.Options.MountName == "" {
		c.printfln("MountName is a required option.")
		c.Help()
		return errors.New("Missing mountname option")
	}

	return nil
}

// setupKlient creates and dials our Klient interface *only* if it is nil. If it is
// not nil, someone else gave a Klient to this Command, and it is expected to be
// dialed and working.
func (c *UnmountCommand) setupKlient() error {
	// if c.klient isnt nil, don't overrite it. Another command may have provided
	// a pre-dialed klient.
	if c.Klient != nil {
		return nil
	}

	k, err := klient.NewDialedKlient(c.KlientOptions)
	if err != nil {
		return fmt.Errorf("Failed to get working Klient instance. err:", err)
	}

	c.Klient = k

	return nil
}

func (c *UnmountCommand) findMountAndPath() error {
	infos, err := c.Klient.RemoteList()
	if err != nil {
		// Using internal error here, because a list error would be confusing to the
		// user.
		c.printfln(GenericInternalError)
		return fmt.Errorf("Failed to get list of machines on mount. err:%s", err)
	}

	info, machineFound := infos.FindFromName(c.Options.MountName)

	// if the machine is found, set the machinename field so that we can correct
	// typos/etc from user input.
	if machineFound {
		c.Options.MountName = info.VMName
	}

	// If options path is empty, get the path before we unmount
	if c.Options.Path == "" {
		p, err := c.mountFinder.FindMountedPathByName(c.Options.MountName)
		if err != nil {
			// removeMountFolder will give the user feedback if path is empty, so
			// we'll just log an error here so we know internally what went wrong. No UX
			// is needed here, yet. We can still unmount successfully.
			c.Log.Error("Failed to FindMountedPath. err:%s", err)
		} else {
			// It's unlikely that p and an error are both returned, but just to be safe,
			// only write a path to Path options if no error was returned.
			c.Options.Path = p
		}
	}

	// If we cannot find the path, or machine, then the there is nothing we can
	// unmount.  Inform the user.
	if !machineFound && c.Options.Path == "" {
		c.printfln(MachineNotFound)
		return errors.New("Unable to unmount, machine not found")
	}

	// if there are no mounts for the given name, and no path was found, then
	// the machine there is nothing we can unmount. Inform the user.
	if len(info.Mounts) == 0 && c.Options.Path == "" {
		c.printfln(MountNotFound)
		return errors.New("Unable to unmount, no mounts found")
	}

	return nil
}

// removeMountFolder removes the mount folder is empty[1], and prints a warning
// to the user if we are unable to remove the folder.
//
// [1]: Due to race conditions, checking if the folder and *then* attempting to
// remove the folder does not guarantee that the folder is actually empty.
// Furthermore, if the folder is not empty, we are not allowed to remove the
// directory anyway. As such, we do not explicitly check for the folder being
// empty.
func (c *UnmountCommand) removeMountFolder() error {
	rmPath := c.Options.Path

	r := util.RemovePath{
		IgnorePaths: c.Options.NeverRemove,
	}
	if err := r.Remove(rmPath); err != nil {
		if err == util.ErrRestrictedPath {
			c.printfln(AttemptedRemoveRestrictedPath)
		} else {
			c.printfln(UnmountFailedRemoveMountPath)
		}

		c.Log.Warning("Unable to remove mountPath:%s, err:%s", rmPath, err)

		// Print a warning, but still return an error for API usage.
		return err
	}

	return nil
}

// Unmount tells klient to unmount the given name and path.
func (c *UnmountCommand) Unmount(name, path string) error {
	req := req.UnmountFolder{
		Name:      name,
		LocalPath: path,
	}

	// currently there's no return response to care about
	if _, err := c.Klient.Tell("remote.unmountFolder", req); err != nil {
		return err
	}

	// track metrics
	metrics.TrackUnmount(name, config.Version)

	return nil
}

func unmount(kite *kite.Client, name, path string, log logging.Logger) error {
	req := req.UnmountFolder{
		Name:      name,
		LocalPath: path,
	}

	// currently there's no return response to care about
	_, err := kite.Tell("remote.unmountFolder", req)
	return err
}
