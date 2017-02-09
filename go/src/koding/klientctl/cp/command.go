// Cp handles the implementation of the `kd cp` command, copying files from one
// machine to another.
//
// See also: klient/remote/cache.go for implementation of the copying logic.
package cp

import (
	"errors"
	"fmt"
	"io"
	"koding/klient/fs"
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
	"path/filepath"
	"strings"

	"github.com/koding/kite/dnode"

	"github.com/koding/logging"
)

var (
	ErrSourceAndDestRemote = errors.New(
		"Both Source and Destination are Remote Machines.",
	)

	ErrSourceAndDestLocal = errors.New(
		"Both Source and Destination are on Local.",
	)
)

const (
	// The constant used when comparing validPosArgs
	localToRemote = "local-to-remote"
)

// Options for the autocomplete install command, generally mapped 1:1 to
// CLI options for the given command.
type Options struct {
	Debug       bool
	Source      string
	Destination string

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
		RemoteReadDirectory(string, string) ([]fs.FileEntry, error)

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

	if err := c.runCp(); err != nil {
		return 1, err
	}

	return 0, nil
}

// handleOptions deals with options, erroring if options are missing, etc.
func (c *Command) handleOptions() error {
	if c.Options.Source == "" {
		c.Stdout.Printlnf(errormessages.SourceRequired)
		c.Stdout.Printlnf("") // print a newline between err msg and help
		c.Help()
		return errors.New("MissingArgument: Options.Source")
	}

	if c.Options.Destination == "" {
		c.Stdout.Printlnf(errormessages.DestinationRequired)
		c.Stdout.Printlnf("") // print a newline between err msg and help
		c.Help()
		return errors.New("MissingArgument: Options.Destination")
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

// getCacheInfo parses the machineName, source and dest paths, and returns the
// cache direction.
//
// This basically translates the `host:path host:path` into `machine:path path` UX.
// Remember that this is needed because the backend uses rsync, which cannot
// use two remotes (and remote.cache has been designed with
// remote->local / local->remote in mind anyway).
//
// In the future we may switch this implementation to use kite, so remote->remote
// is possible.
func (c *Command) parseSourceAndDest() (
	machineName, localPath, remotePath string, localToRemote bool, err error,
) {

	var (
		hasRemoteSource      = strings.Contains(c.Options.Source, ":")
		hasRemoteDestination = strings.Contains(c.Options.Destination, ":")
	)

	if hasRemoteSource && hasRemoteDestination {
		c.Stdout.Printlnf(errormessages.SourceAndDestAreRemote)
		c.Stdout.Printlnf("") // print a newline between err msg and help
		c.Help()
		return "", "", "", false, ErrSourceAndDestRemote
	}

	if !hasRemoteSource && !hasRemoteDestination {
		c.Stdout.Printlnf(errormessages.SourceAndDestAreLocal)
		c.Stdout.Printlnf("") // print a newline between err msg and help
		c.Help()
		return "", "", "", false, ErrSourceAndDestLocal
	}

	if hasRemoteSource {
		split := strings.SplitN(c.Options.Source, ":", 2)
		machineName = split[0]
		remotePath = split[1]
		localPath = c.Options.Destination
		localToRemote = false
	}

	if hasRemoteDestination {
		split := strings.SplitN(c.Options.Destination, ":", 2)
		machineName = split[0]
		remotePath = split[1]
		localPath = c.Options.Source
		localToRemote = true
	}

	return machineName, localPath, remotePath, localToRemote, nil
}

// getMachineFromShortcut gets the machine list and matches the users entry to a valid
// machine. Printing otherwise if unable to do so.
func (c *Command) machineFromShortcut(s string) (string, error) {
	shortcutter := shortcut.NewMachineShortcut(c.Klient)
	machineInfo, err := shortcutter.GetMachineInfoFromShortcut(s)
	switch {
	case err == shortcut.ErrMachineNotFound:
		c.Stdout.Printlnf(errormessages.MachineNotFound)
		return "", err
	case err != nil:
		c.Stdout.Printlnf(errormessages.GenericInternalErrorNoMsg)
		return "", fmt.Errorf("Failed to get list of machines on mount. err:%s", err)
	}

	return machineInfo.VMName, nil
}

func (c *Command) runCp() error {
	// parse the user input Source and Destination, obtaining the remote and local
	// paths, machine name, etc.
	//
	// This provides UX on error!
	machineName, localPath, remotePath, localToRemote, err := c.parseSourceAndDest()
	if err != nil {
		return err
	}

	// Get the machineName from a shortcut, if any was used.
	//
	// This provides UX on error!
	if machineName, err = c.machineFromShortcut(machineName); err != nil {
		return err
	}

	if localPath, err = filepath.Abs(localPath); err != nil {
		c.Stdout.Printlnf(errormessages.GenericInternalErrorNoMsg)
		return err
	}

	c.Log.Debug(
		"Parsed source and dest. machineName:%s, localPath:%s, remotePath%s, localToRemote:%t",
		machineName, localPath, remotePath, localToRemote,
	)

	// This provides UX!
	sshKey, err := c.getSSHKey()
	if err != nil {
		return err
	}

	remoteUsername, err := sshKey.GetUsername(machineName)
	if err != nil {
		c.Stdout.Printlnf(errormessages.FailedGetSSHKey)
		return fmt.Errorf("Error getting remote username. err:%s", err)
	}

	// UX not needed on failure, prepareForSSH prints UX to user.
	if err := c.prepareForSSH(machineName, sshKey); err != nil {
		return err
	}

	c.Stdout.Printlnf(
		"Copying file or directory...",
	)

	sshAuthSock, err := agent.NewClient().GetAuthSock()
	if err != nil || sshAuthSock == "" {
		sshAuthSock = util.GetEnvByKey(os.Environ(), "SSH_AUTH_SOCK")
	}

	cacheReq := req.Cache{
		Debug:             c.Options.Debug,
		Name:              machineName,
		LocalPath:         localPath,
		RemotePath:        remotePath,
		LocalToRemote:     localToRemote,
		Interval:          0, // No interval! Important.
		Username:          remoteUsername,
		SSHAuthSock:       sshAuthSock,
		SSHPrivateKeyPath: sshKey.PrivateKeyPath(),
		// This allows the user to copy files, not just dirs.
		// See option docs for details.
		IncludePath: true,
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

	c.Stdout.Printlnf("Copy complete.")

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

func (c *Command) prepareForSSH(machineName string, sshKey *ssh.SSHKey) error {
	if err := sshKey.PrepareForSSH(machineName); err != nil {
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

func (c *Command) Autocomplete(args ...string) error {
	// If there are no args, autocomplete to machine
	if len(args) == 0 {
		return c.AutocompleteMachineName()
	}

	// Get the last element from the args list, which is the element we want to
	// complete.
	completeArg := args[len(args)-1]

	// If the last arg contains a colon in it, get the remote directory from it.
	if i := strings.IndexRune(completeArg, ':'); i != -1 {
		return c.AutocompleteRemotePath(completeArg[:i], completeArg[i+1:])
	}

	// We were unable to autocomplete a remote path, so autocompleting the machine
	// name by default.
	return c.AutocompleteMachineName()
}

func (c *Command) AutocompleteRemotePath(machineName, remotePath string) error {
	// setup our klient, if needed
	if err := c.setupKlient(); err != nil {
		return err
	}

	// Drop the last path segment, because the last segment is likely the
	// part that the user is trying to autocomplete.
	remotePath = filepath.Dir(remotePath)

	files, err := c.Klient.RemoteReadDirectory(machineName, remotePath)
	if err != nil {
		return err
	}

	for _, f := range files {
		if f.IsDir {
			// Shells complete based on a match to the whole string that the user typed,
			// meaning we need to return a potential match including the entire string.
			//
			// IMPORTANT: The ending slash causes Fish to not add a space at the end
			// of the completion, making the UX much better.
			c.Stdout.Printlnf("%s:%s/", machineName, f.FullPath)
		} else {
			c.Stdout.Printlnf("%s:%s", machineName, f.FullPath)
		}
	}

	return nil
}

func (c *Command) AutocompleteMachineName() error {
	// setup our klient, if needed
	if err := c.setupKlient(); err != nil {
		return err
	}

	infos, err := c.Klient.RemoteList()
	if err != nil {
		return err
	}

	for _, i := range infos {
		// printing the : after it ensures that Fish won't put a space after the string.
		c.Stdout.Printlnf("%s:", i.VMName)
	}

	return nil
}
