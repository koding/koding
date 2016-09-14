package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"koding/klientctl/errormessages"
	"koding/klientctl/ssh/agent"
	"os"
	"os/user"
	"path"
	"path/filepath"
	"strings"
	"time"

	"koding/klient/fs"
	"koding/klient/remote/req"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/klient"
	"koding/klientctl/klientctlerrors"
	"koding/klientctl/list"
	"koding/klientctl/metrics"
	"koding/klientctl/shortcut"
	"koding/klientctl/ssh"
	"koding/klientctl/util"

	"github.com/cheggaaa/pb"
	"github.com/fatih/structs"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
	"golang.org/x/sys/unix"
)

const (
	// a large folder is 1 gig.
	largeFolderBytes = 1 * 1024 * 1024 * 1024
)

var IgnoreFiles = []string{
	".gitignore",
	".hgignore",
}

type MountOptions struct {
	Debug            bool
	Name             string
	LocalPath        string
	RemotePath       string
	NoIgnore         bool
	NoPrefetchMeta   bool
	NoWatch          bool
	PrefetchAll      bool
	PrefetchInterval int
	Trace            bool
	OneWaySync       bool
	OneWayInterval   int
	Fuse             bool

	// Used for Prefetching via RSync (SSH)
	SSHDefaultKeyDir  string
	SSHDefaultKeyName string
}

func (opts *MountOptions) IsZero() bool {
	return structs.IsZero(opts)
}

// Command implements a Command for `kd mount`.
type MountCommand struct {
	Options MountOptions
	Stdout  io.Writer
	Stdin   io.Reader
	Log     logging.Logger

	// The klient instance this struct will use.
	Klient interface {
		RemoteList() (list.KiteInfos, error)
		RemoteCache(req.Cache, func(par *dnode.Partial)) error
		RemoteMountFolder(req.MountFolder) (string, error)
		RemoteReadDirectory(string, string) ([]fs.FileEntry, error)
		RemoteGetPathSize(req.GetPathSizeOptions) (uint64, error)

		// For backwards compatibility with some helper funcs not yet embedded.
		GetClient() *kite.Client

		// These fields are needed for the ssh struct.
		Tell(string, ...interface{}) (*dnode.Partial, error)
		RemoteCurrentUsername(req.CurrentUsernameOptions) (string, error)
	}

	// The options to use if this struct needs to dial Klient.
	//
	// Note! These will be ignored if c.Klient is already defined before Run() is
	// called.
	KlientOptions klient.KlientOptions

	// the following vars exist primarily for mocking ability, and ensuring
	// an enclosed environment within the struct.

	// The Helper. See it's docs for a better understanding of this.
	helper ctlcli.Helper

	// homeDirGetter gets the users home directory.
	homeDirGetter func() (string, error)
}

// Help prints help to the caller.
func (c *MountCommand) Help() {
	if c.helper == nil {
		// Ugh, talk about a bad UX
		fmt.Fprintln(c.Stdout, "Error: Help was requested but mount has no helper.")
		return
	}

	c.helper(c.Stdout)
}

// printf is a helper function for printing to the internal writer.
func (c *MountCommand) printfln(f string, i ...interface{}) {
	if c.Stdout == nil {
		return
	}

	fmt.Fprintf(c.Stdout, f+"\n", i...)
}

// Run the Mount command
func (c *MountCommand) Run() (int, error) {
	// Cleanup local folder when command exists with failure.
	cleanupPath := false
	defer func() {
		if cleanupPath {
			c.cleanupPath()
		}
	}()

	if c.Options.Debug {
		c.Log.SetLevel(logging.DEBUG)
	}

	// allow scp like declaration, ie `<machine name>:/path/to/remote`
	if strings.Contains(c.Options.Name, ":") {
		names := strings.SplitN(c.Options.Name, ":", 2)
		c.Options.Name, c.Options.RemotePath = names[0], names[1]
	}

	// setup our klient, if needed
	if exit, err := c.setupKlient(); err != nil {
		return exit, err
	}

	// Get the machine name from a partial name, if needed.
	if err := c.findMachineName(); err != nil {
		return 1, err
	}

	// Decide smart options, if needed, before the rest of
	// the flow.
	if err := c.smartOptions(); err != nil {
		return 1, err
	}

	if exit, err := c.handleOptions(); err != nil {
		return exit, err
	}

	// create the mount dir if needed
	if err := c.createMountDir(); err != nil {
		return 1, err
	}

	// If they choose not to use fuse, mount with only caching.
	if c.Options.OneWaySync {
		if err := c.useSync(); err != nil {
			cleanupPath = true
			return 1, err
		}
	}

	if c.Options.PrefetchAll {
		if err := c.prefetchAll(); err != nil {
			cleanupPath = true

			return 1, fmt.Errorf("failed to prefetch: %s", err)
		}
	}

	mountRequest := req.MountFolder{
		Debug:           c.Options.Debug,
		Name:            c.Options.Name,
		LocalPath:       c.Options.LocalPath,
		RemotePath:      c.Options.RemotePath,
		NoIgnore:        c.Options.NoIgnore,
		NoPrefetchMeta:  c.Options.NoPrefetchMeta,
		PrefetchAll:     c.Options.PrefetchAll,
		NoWatch:         c.Options.NoWatch,
		CachePath:       getCachePath(c.Options.Name),
		Trace:           c.Options.Trace,
		OneWaySyncMount: c.Options.OneWaySync,
	}

	// Actually mount the folder. Errors are printed by the mountFolder func to the user.
	if err := c.mountFolder(mountRequest); err != nil {
		cleanupPath = true

		return 1, err
	}

	// track metrics
	o := map[string]interface{}{
		"no-ignore":        c.Options.NoIgnore,
		"no-prefetch-meta": c.Options.NoPrefetchMeta,
		"prefetch-all":     c.Options.PrefetchAll,
		"oneway-sync":      c.Options.OneWaySync,
		"no-watch":         c.Options.NoWatch,
		"version":          config.VersionNum(),
	}
	metrics.TrackMount(c.Options.Name, c.Options.LocalPath, o)

	c.printfln("Mount complete.")

	return 0, nil
}

// smartOptions attempts to assign options based on the remote and local environment.
// Eg, if it's a small directory, pure fuse is used. Large directory, and
// onewaysync is used. Massive directory (too big for local system), and fuse is used.
func (c *MountCommand) smartOptions() (err error) {
	if c.hasFlaggedOpts() {
		c.Log.Debug("Mount has flagged options, not using SmartOptions.")
		return nil
	}

	c.Log.Debug("Mount has no flagged options, using SmartOptions.")

	if c.Options.Name == "" || c.Options.LocalPath == "" {
		c.printfln("Mount name and local path are required options.\n")
		c.Help()
		return errors.New("not enough arguments: missing Name or LocalPath")
	}

	// Repeat the message after every smart option return, if no errors.
	// Using a defer to avoid code reuse.
	defer func() {
		if err == nil {
			c.printfln("To manually specify mount options, see: kd mount --help\n")
		}
	}()

	remoteSize, err := c.Klient.RemoteGetPathSize(req.GetPathSizeOptions{
		Debug:      c.Options.Debug,
		Machine:    c.Options.Name,
		RemotePath: c.Options.RemotePath,
	})
	if err != nil {
		c.Log.Error("Unable to get remote path size. err:%s", err)
		if klientctlerrors.IsRemotePathNotExistErr(err) {
			c.printfln(errormessages.RemotePathDoesNotExist)
			return fmt.Errorf("remote path does not exist: %s", err)
		}
		return err
	}

	// Using parent since the given directory will not yet exist.
	localSize, err := getLocalDiskSize(filepath.Dir(c.Options.LocalPath))
	if err != nil {
		c.Log.Error("Unable to get local disk size. err:%s", err)
		return err
	}

	c.Log.Debug(
		"Deciding on smart options. RemotePathSize:%d, LocalDiskSize:%d",
		remoteSize, localSize,
	)

	// if the folder is larger than our specified largeFolderBytes, store isLargeFolder
	// for easy usage.
	isLargeFolder := remoteSize > largeFolderBytes

	// If the mounting the remote folder will take up more than 75% of
	// the local disk, use fuse not rsync, no matter what size the remote folder is.
	if remoteSize > uint64(float64(localSize)*0.75) {
		c.printfln("Remote folder will take more than 75%% of local disk space.")

		if isLargeFolder {
			// no options needed, fuse is default.
			c.printfln("Because of this, mounting via fuse.")
		} else {
			// if the remote folder is large, use fuse caching option.
			c.printfln("Because of this, mounting via fuse and prefetchall.")
			c.Options.PrefetchAll = true
		}

		// fuse is the default, so we don't need any values.
		return nil
	}

	if isLargeFolder {
		c.printfln("Remote folder is over 1Gb, mounting via oneway sync.")
		c.Options.OneWaySync = true
		return nil
	}

	c.printfln("Mounting via fuse.")

	return nil
}

// hasFlaggedOpts checks whether this MountOptions object contains fields which,
// when coming from CLI, use flags. For example:
//
//	`kd mount orange:foo ./foo` == HasFlaggedOpts=false
//	`kd mount orange:foo ./foo -s` == HasFlaggedOpts=true
func (c *MountCommand) hasFlaggedOpts() bool {
	// To figure out if we have flagged opts, we can copy the current opts and
	// remove the positional opts.
	//
	// If the resulting struct is zero value, then it *only* had positional fields,
	// no flagged fields.
	//
	// Likewise if the struct is not zero value, then it must have had some flagged
	// fields.
	noPosOpts := c.Options

	// Set pos opts to zero values.
	noPosOpts.Name = ""
	noPosOpts.LocalPath = ""
	noPosOpts.RemotePath = ""
	// Ignore debug like the others, so that we can --debug smart mounting.
	noPosOpts.Debug = false

	// If these options are using the default config values, then zero them as well.
	// The user did not supply them.
	if noPosOpts.SSHDefaultKeyDir == config.SSHDefaultKeyDir {
		noPosOpts.SSHDefaultKeyDir = ""
	}
	if noPosOpts.SSHDefaultKeyName == config.SSHDefaultKeyName {
		noPosOpts.SSHDefaultKeyName = ""
	}

	return !noPosOpts.IsZero()
}

// handleOptions deals with options, erroring if options are missing, etc.
func (c *MountCommand) handleOptions() (int, error) {
	if c.Options.Name == "" || c.Options.LocalPath == "" {
		c.printfln("Mount name and local path are required options.\n")
		c.Help()
		return 1, errors.New("Not enough arguments")
	}

	if c.Options.OneWaySync {
		var invalidOption bool
		switch {
		case c.Options.Fuse:
			c.printfln(errormessages.InvalidCLIOption, "--fuse", "--oneway-sync")
			invalidOption = true
		case c.Options.PrefetchAll:
			c.printfln(errormessages.InvalidCLIOption, "--prefetch-all", "--oneway-sync")
			invalidOption = true
		case c.Options.NoPrefetchMeta:
			c.printfln(errormessages.InvalidCLIOption, "--noprefetch-meta", "--oneway-sync")
			invalidOption = true
		case c.Options.NoIgnore:
			c.printfln(errormessages.InvalidCLIOption, "--noignore", "--oneway-sync")
			invalidOption = true
		case c.Options.NoWatch:
			c.printfln(errormessages.InvalidCLIOption, "--nowatch", "--oneway-sync")
			invalidOption = true
		}

		if invalidOption {
			return 1, errors.New("Invalid CLI Option.")
		}
	}

	if c.Options.PrefetchInterval == 0 {
		c.Options.PrefetchInterval = 10
		c.Log.Info("Setting interval to default, %d", c.Options.PrefetchInterval)
	}

	if c.Options.NoPrefetchMeta && c.Options.PrefetchAll {
		c.printfln(PrefetchAllAndMetaTogether)
		return 1, fmt.Errorf("noPrefetchMeta and prefetchAll were both supplied")
	}

	// send absolute local path to klient unless local path is empty
	if strings.TrimSpace(c.Options.LocalPath) != "" {
		absoluteLocalPath, err := filepath.Abs(c.Options.LocalPath)
		if err != nil {
			c.Log.Warning(
				"Error encountered while getting absolute path for localPath. err:%s",
				err,
			)
		} else {
			c.Options.LocalPath = absoluteLocalPath
		}
	}

	// remove trailing slashes in remote argument
	if c.Options.RemotePath != "" {
		c.Options.RemotePath = path.Clean(c.Options.RemotePath)
	}

	return 0, nil
}

// createMountDir creates the mount directory if it doesn't already exist.
func (c *MountCommand) createMountDir() error {
	path := c.Options.LocalPath

	_, err := os.Stat(path)
	// To avoid having weird sounding errors, check if we are able to successfully
	// stat that first. If we can, that means the file/dir exists.
	if err == nil {
		c.printfln(CannotMountPathExists)
		return fmt.Errorf("Cannot mount, given path already exists.")
	}

	// If we are unable to read it, but it's *not* an IsNotExist error, then
	// we don't have permission to read that path, or something else is wrong.
	if !os.IsNotExist(err) {
		c.printfln(CannotMountUnableToOpenPath)
		return fmt.Errorf("Error reading mount location. err:%s", err)
	}

	if err := os.MkdirAll(path, 0755); err != nil {
		return fmt.Errorf("Error creating mount dir. err:%s", err)
	}

	return nil
}

// findMachineName gets the machine list and matches the users entry to a valid
// machine. Printing otherwise if unable to do so.
func (c *MountCommand) findMachineName() error {
	shortcutter := shortcut.NewMachineShortcut(c.Klient)
	machineName, err := shortcutter.GetNameFromShortcut(c.Options.Name)
	switch {
	case err == shortcut.ErrMachineNotFound:
		c.printfln(MachineNotFound)
		return err
	case err != nil:
		c.printfln(GenericInternalError)
		return fmt.Errorf("Failed to get list of machines on mount. err:%s", err)
	}

	c.Options.Name = machineName

	return nil
}

// setupKlient creates and dials our Kite interface *only* if it is nil. If it is
// not nil, someone else gave a kite to this Command, and it is expected to be
// dialed and working.
func (c *MountCommand) setupKlient() (int, error) {
	// if c.klient isnt nil, don't overrite it. Another command may have provided
	// a pre-dialed klient.
	if c.Klient != nil {
		return 0, nil
	}

	k, err := klient.NewDialedKlient(c.KlientOptions)
	if err != nil {
		return 1, fmt.Errorf("Failed to get working Klient instance")
	}

	c.Klient = k

	return 0, nil
}

func (c *MountCommand) useSync() error {
	c.Log.Debug("#useSync")

	// If the cachePath exists, move it to the mount location.
	// No need to fail on an error during rename, we can just log it.
	cachePath := getCachePath(c.Options.Name)
	if err := os.Rename(cachePath, c.Options.LocalPath); err != nil {
		c.Log.Warning(
			"Failed to move cache path to mount path. cachePath:%s, localPath:%s, err:%s",
			cachePath, c.Options.LocalPath, err,
		)
	}

	sshKey, err := c.getSSHKey()
	if err != nil {
		return err
	}

	remoteUsername, err := sshKey.GetUsername(c.Options.Name)
	if err != nil {
		c.printfln(FailedGetSSHKey)
		return fmt.Errorf("Error getting remote username. err:%s", err)
	}

	// UX not needed on failure, prepareForSSH prints UX to user.
	if err := c.prepareForSSH(sshKey); err != nil {
		return err
	}

	c.printfln("Downloading initial contents...Please don't interrupt this process while in progress.")

	sshAuthSock, err := agent.NewClient().GetAuthSock()
	if err != nil || sshAuthSock == "" {
		sshAuthSock = util.GetEnvByKey(os.Environ(), "SSH_AUTH_SOCK")
	}

	cacheReq := req.Cache{
		Debug:             c.Options.Debug,
		Name:              c.Options.Name,
		LocalPath:         c.Options.LocalPath,
		RemotePath:        c.Options.RemotePath,
		Interval:          0,
		Username:          remoteUsername,
		SSHAuthSock:       sshAuthSock,
		SSHPrivateKeyPath: sshKey.PrivateKeyPath(),
	}

	if err := c.cacheWithProgress(cacheReq); err != nil {
		return err
	}

	// Modify our cache request with the interval only settings.
	cacheReq.Interval = time.Duration(c.Options.OneWayInterval) * time.Second
	if cacheReq.Interval == 0 {
		cacheReq.Interval = 2 * time.Second
	}

	cacheReq.OnlyInterval = true
	cacheReq.LocalToRemote = true
	cacheReq.IgnoreFile = c.getIgnoreFile(c.Options.LocalPath)

	// c.callRemoteCache handles UX
	return c.callRemoteCache(cacheReq, nil)
}

func (c *MountCommand) prefetchAll() error {
	c.Log.Info("Executing prefetch...")

	sshKey, err := c.getSSHKey()
	if err != nil {
		return err
	}

	remoteUsername, err := sshKey.GetUsername(c.Options.Name)
	if err != nil {
		c.printfln(FailedGetSSHKey)
		return fmt.Errorf("Error getting remote username. err:%s", err)
	}

	// prepareForSSH prints UX to user.
	if err := c.prepareForSSH(sshKey); err != nil {
		return err
	}

	c.printfln("Prefetching remote path...Please don't interrupt this process while in progress.")

	cacheReq := req.Cache{
		Name:              c.Options.Name,
		LocalPath:         getCachePath(c.Options.Name),
		RemotePath:        c.Options.RemotePath,
		Interval:          time.Duration(c.Options.PrefetchInterval) * time.Second,
		Username:          remoteUsername,
		SSHAuthSock:       util.GetEnvByKey(os.Environ(), "SSH_AUTH_SOCK"),
		SSHPrivateKeyPath: sshKey.PrivateKeyPath(),
	}

	return c.cacheWithProgress(cacheReq)
}

func (c *MountCommand) cacheWithProgress(cacheReq req.Cache) (err error) {
	// doneErr is used to wait until the cache progress is done, and also send
	// any error encountered. We simply send nil if there is no error.
	doneErr := make(chan error)

	// The creation of the pb objection presents a CLI progress bar to the user.
	bar := pb.New(100)
	bar.SetMaxWidth(100)
	bar.Start()

	// The callback, used to update the progress bar as remote.cache downloads
	cacheProgressCallback := func(par *dnode.Partial) {
		type Progress struct {
			Progress int        `json:progress`
			Error    kite.Error `json:error`
		}

		// TODO: Why is this an array from Klient? How can this be written cleaner?
		ps := []Progress{Progress{}}
		par.MustUnmarshal(&ps)
		p := ps[0]

		if p.Error.Message != "" {
			doneErr <- p.Error
			c.Log.Error("remote.cacheFolder progress callback returned an error. err:%s", err)
			c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(
				FailedPrefetchFolder,
			))
		}

		bar.Set(p.Progress)

		// TODO: Disable the callback here, so that it's impossible to double call
		// the progress after competion - to avoid weird/bad UX and errors.
		if p.Progress == 100 {
			doneErr <- nil
		}
	}

	// c.callRemoteCache handles UX
	if err := c.callRemoteCache(cacheReq, cacheProgressCallback); err != nil {
		return err
	}

	if err := <-doneErr; err != nil {
		c.printfln("") // newline to ensure the progress bar ends
		c.printfln(
			defaultHealthChecker.CheckAllFailureOrMessagef(FailedPrefetchFolder),
		)
		return fmt.Errorf(
			"remote.cacheFolder progress callback returned an error. err:%s", err,
		)
	}

	bar.Finish()

	return nil
}

// callRemoteCache performs a Klient.RemoteCache request.
func (c *MountCommand) callRemoteCache(r req.Cache, progressCb func(par *dnode.Partial)) error {
	if err := c.Klient.RemoteCache(r, progressCb); err != nil {
		// Because we have a progress bar in the UX currently, we need to add a
		// newline if there's an error.
		c.printfln("")
		switch {
		case klientctlerrors.IsRemotePathNotExistErr(err):
			c.printfln(RemotePathDoesNotExist)
			return fmt.Errorf("Remote path does not exist. err:%s", err)
		case klientctlerrors.IsProcessError(err):
			c.printfln(RemoteProcessFailed, err)
			return err
		default:
			c.printfln(
				defaultHealthChecker.CheckAllFailureOrMessagef(FailedPrefetchFolder),
			)
			return fmt.Errorf("remote.cacheFolder returned an error. err:%s", err)
		}
	}

	return nil
}

func (c *MountCommand) mountFolder(r req.MountFolder) error {
	warning, err := c.Klient.RemoteMountFolder(r)
	if err != nil {
		switch {
		case klientctlerrors.IsExistingMountErr(err):
			util.MustConfirm("This folder is already mounted. Remount? [Y|n]")

			// unmount using mount path
			//
			// TODO: Fix abstraction leak.
			if err := unmount(c.Klient.GetClient(), r.Name, r.LocalPath, c.Log); err != nil {
				c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToUnmount))
				return fmt.Errorf("Error unmounting (remounting). err:%s", err)
			}

			warning, err = c.Klient.RemoteMountFolder(r)
			if err != nil {
				c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToMount))
				return fmt.Errorf("Error mounting (remounting). err:%s", err)
			}

		case klientctlerrors.IsDialFailedErr(err):
			c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(FailedDialingRemote))
			return fmt.Errorf("Error dialing remote klient. err:%s", err)

		case klientctlerrors.IsMachineNotValidYetErr(err):
			c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(MachineNotValidYet))
			return fmt.Errorf("Machine is not valid yet. err:%s", err)

		case klientctlerrors.IsRemotePathNotExistErr(err):
			c.printfln(RemotePathDoesNotExist)
			return fmt.Errorf("Remote path does not exist. err:%s", err)

		case klientctlerrors.IsMachineActionLockedErr(err):
			c.printfln(MachineMountActionIsLocked, r.Name)
			return fmt.Errorf("Machine is locked. err:%s", err)

		default:
			// catch any remaining errors
			c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToMount))
			return fmt.Errorf("Error mounting directory. err:%s", err)
		}
	}

	// TODO: Remove this check? The above switch has a default case, this is useless,
	// right?
	//
	// catch errors other than klientctlerrors.IsExistingMountErr
	if err != nil {
		c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToMount))
		return fmt.Errorf("Error mounting directory. err:%s", err)
	}

	if warning != "" {
		c.printfln("Warning: %s\n", warning)
	}

	return nil
}

func (c *MountCommand) getSSHKey() (*ssh.SSHKey, error) {
	homeDir, err := c.homeDirGetter()
	if err != nil {
		// Using internal error here, because a list error would be confusing to the
		// user.
		c.printfln(GenericInternalError)
		return nil, fmt.Errorf("Failed to get OS User. err:%s", err)
	}

	// TODO: Use the ssh.Command's implementation of this logic, once ssh.Command is
	// moved to this new struct setup.
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

func (c *MountCommand) prepareForSSH(sshKey *ssh.SSHKey) error {
	if err := sshKey.PrepareForSSH(c.Options.Name); err != nil {
		if strings.Contains(err.Error(), "user: unknown user") {
			c.printfln(CannotFindSSHUser)
			return fmt.Errorf("Cannot ssh into managed machines. err:%s", err)
		}

		if klientctlerrors.IsMachineNotValidYetErr(err) {
			c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(MachineNotValidYet))
			return fmt.Errorf("Machine is not valid yet. err:%s", err)
		}

		c.printfln(FailedGetSSHKey)
		return fmt.Errorf("Error getting ssh key. err:%s", err)
	}

	return nil
}

func (c *MountCommand) cleanupPath() {
	if err := util.NewRemovePath().Remove(c.Options.LocalPath); err != nil {
		c.printfln(UnmountFailedRemoveMountPath)
	}
}

func (c *MountCommand) getIgnoreFile(localPath string) string {
	for _, name := range IgnoreFiles {
		p := filepath.Join(localPath, name)
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}

	return ""
}

func (c *MountCommand) Autocomplete(args ...string) error {
	// If there are no args, autocomplete to machine
	if len(args) == 0 {
		return c.AutocompleteMachineName()
	}

	// Get the last element from the args list, which is the element we want to
	// complete.
	completeArg := args[len(args)-1]

	// If the last arg contains a colon in it, get the remote directory from it.
	//
	// TODO: Implement support for --remotepath flag in this same manner.
	if strings.Contains(completeArg, ":") {
		split := strings.SplitN(completeArg, ":", 2)
		machineName, remotePath := split[0], split[1]
		return c.AutocompleteRemotePath(machineName, remotePath)
	}

	// We were unable to autocomplete a remote path, so autocompleting the machine
	// name by default.
	return c.AutocompleteMachineName()
}

func (c *MountCommand) AutocompleteRemotePath(machineName, remotePath string) error {
	// setup our klient, if needed
	if _, err := c.setupKlient(); err != nil {
		return err
	}

	// Drop the last path segment, because the last segment is likely the
	// part that the user is trying to autocomplete.
	remotePath, _ = filepath.Split(remotePath)

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
			// of the competion, making the UX much better.
			c.printfln("%s:%s/", machineName, f.FullPath)
		}
	}

	return nil
}

func (c *MountCommand) AutocompleteMachineName() error {
	// setup our klient, if needed
	if _, err := c.setupKlient(); err != nil {
		return err
	}

	infos, err := c.Klient.RemoteList()
	if err != nil {
		return err
	}

	for _, i := range infos {
		c.printfln(i.VMName)
	}

	return nil
}

// askToCreate checks if the folder does not exist, and creates it
// if the user chooses to. If the user does *not* choose to create it,
// we return an IsNotExist error.
//
// TODO: Handle the case where a user types stuff in before being prompted,
// and then the prompt uses that. Ie, flush the input so that what we
// read is new input from the user. Not tested :)
func askToCreate(p string, r io.Reader, w io.Writer) error {
	_, err := os.Stat(p)

	// If we fail to stat the file, and it's *not* IsNotExist, we may be
	// having permission issues or some other related issue. Return
	// the error.
	if err != nil && !os.IsNotExist(err) {
		return err
	}

	// If there was no error stating the path, it already exists -
	// we can return, as there's nothing we need to do.
	if err == nil {
		return nil
	}

	fmt.Fprint(w,
		"The mount folder does not exist, would you like to create it? [Y/n]",
	)

	// To understand why we're creating a bReader here, please see
	// the docstring on YesNoConfirmWithDefault().
	bReader := bufio.NewReader(r)

	// Retry YesNo confirmation 3 times if needed
	var createFolder bool
	for i := 0; i < 3; i++ {
		createFolder, err = util.YesNoConfirmWithDefault(bReader, true)
		// If the user supplied an accepted value, stop trying
		if err == nil {
			break
		}
		// If err != nil, then the error did not provide an understood
		// response.
		fmt.Fprintln(w, "Invalid response, please type 'yes' or 'no'")
	}

	// If the retry loop exited with an error, the user failed to give
	// a meaningful response to the YesNo confirmation.
	if err != nil {
		return err
	}

	// The user chose not to create the folder. We cannot mount something that
	// doesn't exist - so we must fail here with an error.
	if !createFolder {
		return klientctlerrors.ErrUserCancelled
	}

	return os.Mkdir(p, 0755)
}

func getLocalDiskSize(path string) (uint64, error) {
	var stat unix.Statfs_t
	unix.Statfs(path, &stat)
	return stat.Bavail * uint64(stat.Bsize), nil
}

func getCachePath(name string) string {
	cacheName := fmt.Sprintf("%s.cache", name)
	return filepath.Join(ConfigFolder, cacheName)
}

// homeDirGetter gets the users home directory based on Golang's os/user package.
func homeDirGetter() (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	return usr.HomeDir, nil
}
