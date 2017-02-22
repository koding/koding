// A package implementing the `kd repair` command.
//
// The repair package consists of a Command and various types implementing Repairer.
// This repairier is responsible for looking at the given mount and identifying
// a specific problem, and fixing it when possible.
package repair

import (
	"errors"
	"fmt"
	"io"
	"time"

	"koding/klient/command"
	"koding/klient/remote/req"
	"koding/klientctl/ctlcli"
	"koding/klientctl/exitcodes"
	"koding/klientctl/klient"
	"koding/klientctl/list"
	"koding/klientctl/metrics"
	"koding/klientctl/util"
	"koding/klientctl/util/exec"
	"koding/mountcli"

	"github.com/koding/logging"
	"github.com/koding/service"
)

type Options struct {
	MountName string
	Version   int
}

// Command implements the klientctl.Command interface for KD Repair
type Command struct {
	Options Options
	Stdout  io.Writer
	Stdin   io.Reader
	Log     logging.Logger

	// A collection of Repairers responsible for actually repairing a given mount.
	// Executed in the order they are defined, the effectiveness of the Repairers
	// may depend on the order they are run in. An example being TokenNotValidYetRepair
	// likely should be run *after* a restart, as Tokens not being valid yet usually
	// happens after a restart.
	// Order matters.
	Repairers []Repairer

	// A collection of Repairers responsible for repairing anything that this command
	// needs to run. Namely making sure internet is working, klient is working, etc.
	// Order matters.
	SetupRepairers []Repairer

	// The klient instance this struct will use, mainly given to Repairers.
	Klient interface {
		RemoteList() (list.KiteInfos, error)
		RemoteStatus(req.Status) error
		RemoteMountInfo(string) (req.MountInfoResponse, error)
		RemoteRemount(string) error
		RemoteExec(string, string) (command.Output, error)
	}

	// The options to use if this struct needs to dial Klient.
	//
	// Note! These will be ignored if c.Klient is already defined before Run() is
	// called.
	KlientOptions klient.KlientOptions

	// A struct that provides functionality for starting and stopping klient
	KlientService interface {
		Start() error
		Stop() error
		IsKlientRunning() bool
	}

	// the following vars exist primarily for mocking ability, and ensuring
	// an enclosed environment within the struct.

	// The ctlcli Helper. See the type docs for a better understanding of this.
	Helper ctlcli.Helper

	// Due to the service not being packaged currently, we have to be provided with
	// a constructor function to create a preconfigured service. We'll use that,
	// to create our proper KlientService.
	ServiceConstructor func() (service.Service, error)
}

// Help prints help to the caller.
func (c *Command) Help() {
	if c.Helper == nil {
		// Ugh, talk about a bad UX
		fmt.Fprintln(c.Stdout, "Error: Help was requested but command has no helper.")
		return
	}

	c.Helper(c.Stdout)
}

// printf is a helper function for printing to the internal writer.
func (c *Command) printfln(f string, i ...interface{}) {
	if c.Stdout == nil {
		return
	}

	fmt.Fprintf(c.Stdout, f+"\n", i...)
}

// Run the Mount command
func (c *Command) Run() (_ int, err error) {
	var mountName = c.Options.MountName

	defer func() {
		if err != nil {
			metrics.TrackRepairError(mountName, err.Error(), c.Options.Version)
		}
	}()

	go func() {
		metrics.TrackRepair(mountName, c.Options.Version)
	}()

	if err := c.handleOptions(); err != nil {
		return exitcodes.RepairHandleOptionsErr, err
	}

	if err := c.initService(); err != nil {
		return exitcodes.RepairInitServiceErr, err
	}

	if err := c.initSetupRepairers(); err != nil {
		return exitcodes.RepairInitSetupRepairersErr, err
	}

	if err := c.runRepairers(c.SetupRepairers); err != nil {
		return exitcodes.RepairRunSetupRepairersErr, err
	}

	if err := c.setupKlient(); err != nil {
		return exitcodes.RepairSetupKlientErr, err
	}

	// Only run the kontrol repairers if we have not already explicitly defined
	// repairers ahead of time.
	if c.Repairers == nil {
		// The kontrol repairer will check if we're connected to kontrol yet, and
		// attempt to wait for it. Eventually restarting if needed.
		kontrolRepair := []Repairer{
			&KontrolRepair{
				Log:    c.Log.New("KontrolRepair"),
				Stdout: c.Stdout,
				Klient: c.Klient,
				RetryOptions: RetryOptions{
					StatusRetries: 3,
					StatusDelay:   10 * time.Second,
				},
				Exec: &exec.CommandRun{
					Stdin:  c.Stdin,
					Stdout: c.Stdout,
				},
			},
		}

		// TODO: Remove this. Currently this exists because we're manually running it
		// before the checkMachineExist() call. This is to ensure we check kontrol
		// before running remote.list inside of klient (which requires kontrol)
		if err := c.runRepairers(kontrolRepair); err != nil {
			return exitcodes.RepairRunSetupRepairersErr, err
		}
	}

	// Check for the existence of the machine *after* we run the repairers. That
	// way the setup repairers can check for the health of klient, start it, etc.
	if err := c.checkMachineExist(); err != nil {
		return exitcodes.RepairCheckMachineExistErr, err
	}

	if err := c.initDefaultRepairers(); err != nil {
		return exitcodes.RepairInitDefaultRepairersErr, err
	}

	if err := c.runRepairers(c.Repairers); err != nil {
		return exitcodes.RepairRunDefaultRepairersErr, err
	}

	c.printfln("Everything looks healthy.")

	return exitcodes.Success, nil
}

func (c *Command) handleOptions() error {
	if c.Options.MountName == "" {
		c.printfln("MountName is a required option.")
		c.Help()
		return errors.New("Missing mountname option")
	}

	return nil
}

// initSetupRepairers handles creating the repairers that Command needs to operate,
// namely dealing with starting klient, or requirements for klient to run.
//
// If klient isn't able to run, we can't run most of our repairers anyway - that's
// what this one deals with.
func (c *Command) initSetupRepairers() error {
	if c.SetupRepairers != nil {
		return nil
	}

	// Our internet repairer retries status many times, until it finally gives up.
	internetRepair := &InternetRepair{
		Stdout:               c.Stdout,
		InternetConfirmAddrs: DefaultInternetConfirmAddrs,
		HTTPTimeout:          time.Second,
		RetryOpts: RetryOptions{
			StatusRetries: 900,
			StatusDelay:   1 * time.Second,
		},
	}

	// The klient running repairer, will check if klient is running and connectable,
	// and restart it if not.
	klientRunningRepair := &KlientRunningRepair{
		Stdout:        util.NewFprint(c.Stdout),
		KlientOptions: c.KlientOptions,
		KlientService: c.KlientService,
		Exec: &exec.CommandRun{
			Stdin:  c.Stdin,
			Stdout: c.Stdout,
		},
	}

	// A collection of Repairers responsible for actually repairing a given mount.
	// Executed in the order they are defined, the effectiveness of the Repairers
	// may depend on the order they are run in.
	// *Order matters*
	c.SetupRepairers = []Repairer{
		internetRepair,
		klientRunningRepair,
	}

	return nil
}

// setupKlient creates and dials our Kite interface *only* if it is nil. If it is
// not nil, someone else gave a kite to this Command, and it is expected to be
// dialed and working.
//
// TODO: Move this logic to a repairer, since failing to connect is part of a
// repairers workflow.
func (c *Command) setupKlient() error {
	// if c.klient isnt nil, don't overrite it. Another command may have provided
	// a pre-dialed klient.
	if c.Klient != nil {
		return nil
	}

	k, err := klient.NewDialedKlient(c.KlientOptions)
	if err != nil {
		return fmt.Errorf("Failed to get working Klient instance. err:%s", err)
	}

	c.Klient = k

	return nil
}

// checkMachineExists will list the remote machines and check if the given machine
// exists.
//
// TODO: This function needs to list *all* machines, offline or online, because
// offline machines may be in need of repair. This is not currently possible,
// but will be implemented by TMS-2443.
func (c *Command) checkMachineExist() error {
	infos, err := c.Klient.RemoteList()

	// Because we just ran health checks against Kontrol, this really shouldn't happen.
	// Lets log a meaningful message to the user.
	//
	// Asking them to run repair again (so we can run the repairers again) seems
	// reasonable. We could of course manually run the repairers, but that seems like
	// a good way to confuse order of operations for our developers.
	if err != nil {
		// TODO: Senthil, fix this message please.
		c.printfln(
			`Error: Unable to list machines from koding.com.
There maybe be a connectivity problem. Please try again.`,
		)
		return err
	}

	info, ok := infos.FindFromName(c.Options.MountName)
	if !ok {
		err := fmt.Errorf("Error: Machine %q does not exist.", c.Options.MountName)
		c.printfln(err.Error())
		return err
	}

	// If klient can't find the mount, we don't have enough data to remount.
	// We can't do anything unfortunately. Inform the user, and return an error.
	//if _, err := c.Klient.RemoteMountInfo(r.MountName); err != nil {
	if len(info.Mounts) == 0 {
		err := fmt.Errorf(
			"Error: Machine %q is not mounted.", c.Options.MountName,
		)
		c.printfln(err.Error())
		return err
	}

	return nil
}

// initService creates our KlientService if it is nil.
//
// TODO: The creation of KlientService can be cleaned up a lot once the klientctl
// config is properly packaged. When that happens we can access whatever config
// variables we need, and won't need the service constructor.
func (c *Command) initService() error {
	if c.KlientService != nil {
		return nil
	}

	if c.ServiceConstructor == nil {
		return errors.New("Unable to create KlientService. Both KlientService and ServiceConstructor are nil.")
	}

	service, err := c.ServiceConstructor()
	if err != nil {
		return fmt.Errorf("Unable to create Service instance. err:%s", err)
	}

	c.KlientService = &klient.KlientService{
		Service:       service,
		KlientAddress: c.KlientOptions.Address,
		PauseInterval: time.Second,
		MaxAttempts:   10,
	}

	return nil
}

// initDefaultRepairers creates the repairers for this Command if the
// Command.Repairers field is *nil*. This allows a caller can specify their own
// repairers if desired.
func (c *Command) initDefaultRepairers() error {
	if c.Repairers != nil {
		return nil
	}

	// TODO: Re-enable. Currently disabled because we're manually running it
	// before the checkMachineExist() call inside of Run().
	//
	//// The kontrol repairer will check if we're connected to kontrol yet, and
	//// attempt to wait for it. Eventually restarting if needed.
	//kontrolRepair := &KontrolRepair{
	//	Log:    c.Log.New("KontrolRepair"),
	//	Stdout: c.Stdout,
	//	Klient: c.Klient,
	//	RetryOptions: RetryOptions{
	//		StatusRetries: 3,
	//		StatusDelay:   10 * time.Second,
	//	},
	//	Exec: &exec.CommandRun{
	//		Stdin:  c.Stdin,
	//		Stdout: c.Stdout,
	//	},
	//}

	// The kite unreachable repairer ensures that the remote machine is on, and
	// kite is reachable. No repair action is possible.
	kiteUnreachableRepair := &KiteUnreachableRepair{
		Log:           c.Log.New("KiteUnreachableRepair"),
		Stdout:        c.Stdout,
		Klient:        c.Klient,
		StatusRetries: 10,
		StatusDelay:   1 * time.Second,
		MachineName:   c.Options.MountName,
	}

	// The token expired repair checks for token expired. This should be placed *before*
	// TokenNotYetValidRepair, so that after we restart, we can check if the token
	// is valid.
	tokenExpired := &TokenExpiredRepair{
		Log:                c.Log.New("TokenExpiredRepair"),
		Stdout:             c.Stdout,
		Klient:             c.Klient,
		RepairWaitForToken: 5 * time.Second,
		MachineName:        c.Options.MountName,
	}

	// The token not yet valid repairer will check if we're failing from the token
	// not yet valid error, and wait for it to become valid.
	tokenNotValidYetRepair := &TokenNotYetValidRepair{
		Log:           c.Log.New("TokenNotYetValidRepair"),
		Stdout:        c.Stdout,
		Klient:        c.Klient,
		RepairRetries: 5,
		RepairDelay:   3 * time.Second,
		MachineName:   c.Options.MountName,
	}

	mountExistsRepair := &MountExistsRepair{
		Log:       c.Log.New("MountExistsRepair"),
		Stdout:    util.NewFprint(c.Stdout),
		MountName: c.Options.MountName,
		Klient:    c.Klient,
		Mountcli:  mountcli.NewMountcli(),
	}

	permDeniedRepair := &PermDeniedRepair{
		Log:       c.Log.New("PermDeniedRepair"),
		Stdout:    util.NewFprint(c.Stdout),
		MountName: c.Options.MountName,
		Klient:    c.Klient,
	}

	mountEmptyRepair := &MountEmptyRepair{
		Log:       c.Log.New("MountEmptyRepair"),
		Stdout:    util.NewFprint(c.Stdout),
		MountName: c.Options.MountName,
		Klient:    c.Klient,
	}

	deviceNotConfiguredRepair := &DeviceNotConfiguredRepair{
		Log:       c.Log.New("DeviceNotConfiguredRepair"),
		Stdout:    util.NewFprint(c.Stdout),
		MountName: c.Options.MountName,
		Klient:    c.Klient,
	}

	writeReadRepair := &WriteReadRepair{
		Log:       c.Log.New("WriteReadRepair"),
		Stdout:    util.NewFprint(c.Stdout),
		MountName: c.Options.MountName,
		Klient:    c.Klient,
	}

	// A collection of Repairers responsible for actually repairing a given mount.
	// Executed in the order they are defined, the effectiveness of the Repairers
	// may depend on the order they are run in. An example being TokenNotValidYetRepair
	// likely should be run *after* a restart, as Tokens not being valid yet usually
	// happens after a restart.
	c.Repairers = []Repairer{
		//kontrolRepair,
		kiteUnreachableRepair,
		tokenExpired,
		tokenNotValidYetRepair,
		mountExistsRepair,
		permDeniedRepair,
		mountEmptyRepair,
		deviceNotConfiguredRepair,
		writeReadRepair,
	}

	return nil
}

// runRepairers executes the given repairers. First running Statuses, and then
// Repair() on any of the Statuses that don't succeed. If any Repairs fail,
// the error is returned. It is the responsibility of the Repairer (usually via the
// RetryRepairer) to repeat repair attempts on failures.
func (c *Command) runRepairers(repairers []Repairer) error {
	for _, r := range repairers {
		ok, err := r.Status()
		if err != nil {
			c.Log.Error("Repairer was unable to determine Status. Repairer not configured properly or requirements not met. repairer:%s, err:%s", r, err)
			return err
		}

		if ok {
			// If there is no problem from Status, we can just move onto the next Repairer.
			continue
		}

		c.Log.Warning(
			"Repairer returned a non-ok status. Running its repair. repairer:%s", r,
		)

		if err := r.Repair(); err != nil {
			c.Log.Error("Repairer failed to repair. repairer:%s, err:%s", r, err)
			return err
		}
	}

	return nil
}
