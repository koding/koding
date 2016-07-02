// The core logic for the `kd sync` command.
//
// Note this command is not currently provided by ctl binary, as it was deemed
// unneeded due to the current UX of one way sync (deletions of remote files). This
// package is kept in the event that one way sync UX changes, to require this utility.
package sync

import (
	"errors"
	"fmt"
	"io"
	"koding/klient/remote/req"
	"koding/klient/remote/restypes"
	"koding/klientctl/ctlcli"
	"koding/klientctl/errormessages"
	"koding/klientctl/klient"
	"koding/klientctl/klientctlerrors"
	"koding/klientctl/list"
	"koding/klientctl/mount"
	"koding/klientctl/shortcut"
	"koding/klientctl/ssh"
	"koding/klientctl/ssh/agent"
	"koding/klientctl/util"
	"os"
	"path"
	"strings"

	"github.com/koding/kite/dnode"

	"github.com/koding/logging"
)

var (
	validPosArgs = []string{"remote-to-local", localToRemote}
)

const (
	// The constant used when comparing validPosArgs
	localToRemote = "local-to-remote"
)

// Options for the autocomplete install command, generally mapped 1:1 to
// CLI options for the given command.
type Options struct {
	Debug         bool
	MountName     string
	SyncDirection string // The 1st position arg, one of validPosArgs

	// Used for Prefetching via RSync (SSH)
	SSHDefaultKeyDir  string
	SSHDefaultKeyName string
}

// Init contains various instances required for a Command instance to be initialized.
type Init struct {
	Stdout io.Writer
	Log    logging.Logger

	// The options to use if this struct needs to dial Klient.
	//
	// Note! These will be ignored if c.Klient is already defined before Run() is
	// called.
	KlientOptions klient.KlientOptions

	// The klient instance this struct will use.
	Klient interface {
		RemoteList() (list.KiteInfos, error)
		RemoteCache(req.Cache, func(par *dnode.Partial)) error

		// These fields are needed for the ssh struct.
		Tell(string, ...interface{}) (*dnode.Partial, error)
		RemoteCurrentUsername(req.CurrentUsernameOptions) (string, error)
	}

	// The ctlcli Helper. See the type docs for a better understanding of this.
	Helper ctlcli.Helper

	// HomeDirGetter gets the users home directory.
	HomeDirGetter func() (string, error)

	HealthChecker interface {
		CheckAllFailureOrMessagef(string, ...interface{}) string
	}
}

func (i Init) CheckValid() error {
	if i.Stdout == nil {
		return errors.New("MissingArgument: Stdout")
	}

	if i.Log == nil {
		return errors.New("MissingArgument: Log")
	}

	if i.Helper == nil {
		return errors.New("MissingArgument: Helper")
	}

	if i.HomeDirGetter == nil {
		return errors.New("MissingArgument: HomeDirGetter")
	}

	if i.HealthChecker == nil {
		return errors.New("MissingArgument: HealthChecker")
	}

	return nil
}

// Command implements the klientctl.Command interface for `kd sync`
type Command struct {
	// Embedded Init gives us our Klient/etc instances.
	Init
	Options Options
	Stdout  *util.Fprint

	// mountInfo is used to locate the remote and local folder, based on the
	// existing mount.
	mountInfo restypes.ListMountInfo
}

func NewCommand(i Init, o Options) (*Command, error) {
	if err := i.CheckValid(); err != nil {
		return nil, err
	}

	if o.Debug {
		i.Log.SetLevel(logging.DEBUG)
	}

	c := &Command{
		Init:    i,
		Options: o,
		// Override the init stdout writer with an Fprint writer
		Stdout: util.NewFprint(i.Stdout),
	}

	return c, nil
}

// Help prints help to the caller.
func (c *Command) Help() {
	c.Helper(c.Stdout)
}

func (c *Command) Run() (int, error) {
	if err := c.handleOptions(); err != nil {
		return 1, err
	}

	if err := c.setupKlient(); err != nil {
		return 1, err
	}

	if err := c.mountFromShortcut(); err != nil {
		return 1, err
	}

	if err := c.runSync(); err != nil {
		return 1, err
	}

	return 0, nil
}

func (c *Command) Autocomplete(args ...string) error {
	for _, cmplt := range validPosArgs {
		fmt.Fprintln(c.Stdout, cmplt)
	}
	return nil
}

// handleOptions deals with options, erroring if options are missing, etc.
func (c *Command) handleOptions() error {
	if c.Options.SyncDirection == "" {
		c.Stdout.Printlnf(errormessages.SyncDirectionRequired)
		c.Stdout.Printlnf("") // print a newline between err msg and help
		c.Help()
		return errors.New("MissingArgument: Options.SyncDirection")
	}

	var validDirection bool
	for _, validPosArg := range validPosArgs {
		if validPosArg == c.Options.SyncDirection {
			validDirection = true
		}
	}

	if !validDirection {
		c.Stdout.Printlnf(errormessages.InvalidSyncDirection, c.Options.SyncDirection)
		c.Stdout.Printlnf("") // print a newline between err msg and help
		c.Help()
		return fmt.Errorf(
			"InvalidArgument: Options.SyncDirection == %q", c.Options.SyncDirection,
		)
	}

	return nil
}

// setupKlient creates and dials our Kite interface *only* if it is nil. If it is
// not nil, someone else gave a kite to this Command, and it is expected to be
// dialed and working.
func (c *Command) setupKlient() error {
	// if c.klient isnt nil, don't overrite it. Another command may have provided
	// a pre-dialed klient.
	if c.Klient != nil {
		return nil
	}

	k, err := klient.NewDialedKlient(c.KlientOptions)
	if err != nil {
		return fmt.Errorf("Failed to get working Klient instance")
	}

	c.Klient = k

	return nil
}

// mountFromShortcut gets the machine list and matches the users entry to a valid
// machine. Printing otherwise if unable to do so.
func (c *Command) mountFromShortcut() error {
	shortcutter := shortcut.NewMachineShortcut(c.Klient)
	machineInfo, err := shortcutter.GetMachineInfoFromShortcut(c.Options.MountName)
	switch {
	case err == shortcut.ErrMachineNotFound:
		c.Stdout.Printlnf(errormessages.MachineNotFound)
		return err
	case err != nil:
		c.Stdout.Printlnf(errormessages.GenericInternalErrorNoMsg)
		return fmt.Errorf("Failed to get list of machines on mount. err:%s", err)
	}

	c.Options.MountName = machineInfo.VMName

	var foundMountInfo bool
	for _, mountInfo := range machineInfo.Mounts {
		if mountInfo.MountName == c.Options.MountName {
			foundMountInfo = true
			c.mountInfo = mountInfo
			break
		}
	}

	if !foundMountInfo {
		c.Stdout.Printlnf(errormessages.MountNotFound)
		return fmt.Errorf("No mount found for name %q", c.Options.MountName)
	}

	return nil
}

func (c *Command) runSync() error {
	sshKey, err := c.getSSHKey()
	if err != nil {
		return err
	}

	remoteUsername, err := sshKey.GetUsername(c.Options.MountName)
	if err != nil {
		c.Stdout.Printlnf(errormessages.FailedGetSSHKey)
		return fmt.Errorf("Error getting remote username. err:%s", err)
	}

	// UX not needed on failure, prepareForSSH prints UX to user.
	if err := c.prepareForSSH(sshKey); err != nil {
		return err
	}

	c.Stdout.Printlnf(
		"Downloading initial contents...Please don't interrupt this process while in progress.",
	)

	sshAuthSock, err := agent.NewClient().GetAuthSock()
	if err != nil || sshAuthSock == "" {
		sshAuthSock = util.GetEnvByKey(os.Environ(), "SSH_AUTH_SOCK")
	}

	cacheReq := req.Cache{
		Debug:             c.Options.Debug,
		Name:              c.Options.MountName,
		LocalPath:         c.mountInfo.LocalPath,
		RemotePath:        c.mountInfo.RemotePath,
		LocalToRemote:     c.Options.SyncDirection == localToRemote,
		Interval:          0, // No interval! Important.
		Username:          remoteUsername,
		SSHAuthSock:       sshAuthSock,
		SSHPrivateKeyPath: sshKey.PrivateKeyPath(),
	}

	cb, err := mount.NewCacheCallback(mount.CacheCallbackInit{
		Log:    c.Log,
		Stdout: c.Stdout,
	})
	if err != nil {
		c.Stdout.Printlnf(errormessages.GenericInternalErrorNoMsg)
		return err
	}

	// UX not needed on error, remoteCache handles that.
	//
	// Note that because we used a callback, this is async - updates are sent to the
	// callback and progress bar. We'll wait and block, below.
	if err := c.callRemoteCache(cacheReq, cb.Callback); err != nil {
		return err
	}

	// Wait until the async callback is done, then check for an error.
	if err := cb.WaitUntilDone(); err != nil {
		c.Stdout.Printlnf(
			c.HealthChecker.CheckAllFailureOrMessagef(errormessages.FailedSyncFolder),
		)
		return fmt.Errorf("remote.cacheFolder returned an error. err:%s", err)
	}

	c.Stdout.Printlnf("Sync complete.")

	return nil
}

func (c *Command) getSSHKey() (*ssh.SSHKey, error) {
	homeDir, err := c.HomeDirGetter()
	if err != nil {
		c.Stdout.Printlnf(errormessages.GenericInternalErrorNoMsg)
		return nil, fmt.Errorf("Failed to get OS User. err:%s", err)
	}

	sshKey := &ssh.SSHKey{
		Log:     c.Log,
		KeyPath: path.Join(homeDir, c.Options.SSHDefaultKeyDir),
		KeyName: c.Options.SSHDefaultKeyName,
		Klient:  c.Klient,
	}

	if !sshKey.KeysExist() {
		// TODO: Fix this environment leak.
		util.MustConfirm("The 'prefetchAll' flag needs to create public/private rsa key pair. Continue? [Y|n]")
	}

	return sshKey, nil
}

func (c *Command) prepareForSSH(sshKey *ssh.SSHKey) error {
	if err := sshKey.PrepareForSSH(c.Options.MountName); err != nil {
		if strings.Contains(err.Error(), "user: unknown user") {
			c.Stdout.Printlnf(errormessages.CannotFindSSHUser)
			return fmt.Errorf("Cannot ssh into managed machines. err:%s", err)
		}

		if klientctlerrors.IsMachineNotValidYetErr(err) {
			c.Stdout.Printlnf(
				c.HealthChecker.CheckAllFailureOrMessagef(errormessages.MachineNotValidYet),
			)
			return fmt.Errorf("Machine is not valid yet. err:%s", err)
		}

		c.Stdout.Printlnf(errormessages.FailedGetSSHKey)
		return fmt.Errorf("Error getting ssh key. err:%s", err)
	}

	return nil
}

// callRemoteCache performs a Klient.RemoteCache request.
func (c *Command) callRemoteCache(r req.Cache, progressCb func(par *dnode.Partial)) error {
	if err := c.Klient.RemoteCache(r, progressCb); err != nil {
		// Because we have a progress bar in the UX currently, we need to add a
		// newline if there's an error.
		c.Stdout.Printlnf("")
		switch {
		case klientctlerrors.IsRemotePathNotExistErr(err):
			c.Stdout.Printlnf(errormessages.RemotePathDoesNotExist)
			return fmt.Errorf("Remote path does not exist. err:%s", err)
		case klientctlerrors.IsProcessError(err):
			c.Stdout.Printlnf(errormessages.RemoteProcessFailed, err)
			return err
		default:
			c.Stdout.Printlnf(
				c.HealthChecker.CheckAllFailureOrMessagef(errormessages.FailedPrefetchFolder),
			)
			return fmt.Errorf("remote.cacheFolder returned an error. err:%s", err)
		}
	}

	return nil
}
