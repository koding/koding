package repair

import (
	"errors"
	"fmt"
	"io"
	"time"

	"koding/klientctl/ctlcli"
	"koding/klientctl/klient"
	"koding/klientctl/util/exec"

	"github.com/koding/logging"
	"github.com/leeola/service"
)

type Options struct {
	MountName string
}

// Command implements the klientctl.Command interface for KD Repair
type Command struct {
	Options Options
	Stdout  io.Writer
	Stdin   io.Reader
	Log     logging.Logger

	// A collection of Repairers responsible for actually repairing a given mount.
	Repairers []Repairer

	// The klient instance this struct will use, mainly given to Repairers.
	//Klient interface {
	//}

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
func (c *Command) Run() (int, error) {
	if err := c.handleOptions(); err != nil {
		return 1, err
	}

	if err := c.initService(); err != nil {
		return 2, err
	}

	if err := c.initDefaultRepairers(); err != nil {
		return 3, err
	}

	if err := c.runRepairers(); err != nil {
		return 4, err
	}

	c.printfln("Everything looks healthy")

	return 0, nil
}

func (c *Command) handleOptions() error {
	if c.Options.MountName == "" {
		c.printfln("MountName is a required option.")
		c.Help()
		return errors.New("Missing mountname option")
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

	// Our internet repairer retries status many times, until it finally gives up.
	internetRepair := &InternetRepair{
		Stdout:               c.Stdout,
		InternetConfirmAddrs: DefaultInternetConfirmAddrs,
		HTTPTimeout:          time.Second,
		RetryOpts: RetryOptions{
			StatusRetries: 10,
			StatusDelay:   1 * time.Second,
		},
	}

	// The klient running repairer, will check if klient is running and connectable,
	// and restart it if not.
	klientRunningRepair := &KlientRunningRepair{
		KlientOptions: c.KlientOptions,
		KlientService: c.KlientService,
		Exec: &exec.CommandRun{
			Stdin:  c.Stdin,
			Stdout: c.Stdout,
		},
	}

	c.Repairers = []Repairer{
		internetRepair,
		klientRunningRepair,
	}

	return nil
}

// runRepairers executes the given repairers. First running Statuses, and then
// Repair() on any of the Statuses that don't succeed. If any Repairs fail,
// the error is returned. It is the responsibility of the Repairer (usualy via the
// RetryRepairer) to repeat repair attempts on failures.
func (c *Command) runRepairers() error {
	// If there are no repairers to run, the core functionality of this command
	// is incapable of working. So, return an error.
	if len(c.Repairers) == 0 {
		return errors.New("Repair command has 0 repairers.")
	}

	for _, r := range c.Repairers {
		ok, err := r.Status()

		// If there is no problem from Status, we can just move onto the next Repairer.
		if ok {
			continue
		}

		c.Log.Warning(
			"Repairer returned a non-ok status. Running its repair. repairer:%s, err:%s",
			r, err,
		)

		err = r.Repair()
		if err != nil {
			c.Log.Error("Repairer failed to repair. repairer:%s, err:%s", r, err)
			return err
		}
	}

	return nil
}
