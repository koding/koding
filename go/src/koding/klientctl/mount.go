package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"os/user"
	"path"
	"path/filepath"
	"strings"
	"time"

	"koding/klient/remote/req"
	"koding/klientctl/klientctlerrors"
	"koding/klientctl/util"

	"github.com/cheggaaa/pb"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
)

type MountOptions struct {
	Name             string
	LocalPath        string
	RemotePath       string
	NoIgnore         bool
	NoPrefetchMeta   bool
	NoWatch          bool
	PrefetchAll      bool
	PrefetchInterval int

	// Used for Prefetching via RSync (SSH)
	SSHDefaultKeyDir  string
	SSHDefaultKeyName string
}

// Command implements a Command for `kd mount`.
type MountCommand struct {
	Options MountOptions
	Stdout  io.Writer
	Stdin   io.Reader
	Log     logging.Logger

	// The klient instance this struct will use.
	Klient interface {
		RemoteList() (KiteInfos, error)
		RemoteCache(req.Cache, func(par *dnode.Partial)) error
		RemoteMountFolder(req.MountFolder) (string, error)

		// For backwards compatibility with some helper funcs not yet embedded.
		GetClient() *kite.Client

		// Tell is here solely for the SSH struct. Need to make that struct use
		// a fully abstracted, Klient interface.
		Tell(string, ...interface{}) (*dnode.Partial, error)
	}

	// The options to use if this struct needs to dial Klient.
	//
	// Note! These will be ignored if c.Klient is already defined before Run() is
	// called.
	KlientOptions KlientOptions

	// the following vars exist primarily for mocking ability, and ensuring
	// an enclosed environment within the struct.

	// The Helper. See it's docs for a better understanding of this.
	helper Helper

	// homeDirGetter gets the users home directory.
	homeDirGetter func() (string, error)

	// mount Lock func. Ie, it creates the lock files we currently use to
	// say what is a mount.
	mountLocker func(string, string) error
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
	if exit, err := c.handleOptions(); err != nil {
		return exit, err
	}

	// setup our klient, if needed
	if exit, err := c.setupKlient(); err != nil {
		return exit, err
	}

	// create the mount dir if needed
	if err := c.createMountDir(); err != nil {
		return 1, err
	}

	// TODO: Try out using Cache Only here, we don't need a new VM list.
	infos, err := c.Klient.RemoteList()
	if err != nil {
		// Using internal error here, because a list error would be confusing to the
		// user.
		//
		// TODO: Healthcheck here!
		c.printfln(GenericInternalError)
		return 1, fmt.Errorf("Failed to get list of machines on mount. err:%s", err)
	}

	// Find the machine by a name, even if partial.
	if info, ok := infos.FindFromName(c.Options.Name); ok {
		c.Options.Name = info.VMName
	}

	if c.Options.PrefetchAll {
		if err := c.prefetchAll(); err != nil {
			return 1, fmt.Errorf("Failed to prefetch. err:%s", err)
		}
	}

	mountRequest := req.MountFolder{
		Name:           c.Options.Name,
		LocalPath:      c.Options.LocalPath,
		RemotePath:     c.Options.RemotePath,
		NoIgnore:       c.Options.NoIgnore,
		NoPrefetchMeta: c.Options.NoPrefetchMeta,
		PrefetchAll:    c.Options.PrefetchAll,
		NoWatch:        c.Options.NoWatch,
		CachePath:      getCachePath(c.Options.Name),
	}

	// Actually mount the folder. Errors are printed by the mountFolder func to the user.
	if err := c.mountFolder(mountRequest); err != nil {
		return 1, err
	}

	// Lock the mount, so that run/etc knows it's a mount folder.
	if err := c.mountLocker(c.Options.LocalPath, c.Options.Name); err != nil {
		c.printfln(FailedToLockMount)
		return 1, fmt.Errorf("Error locking. err:%s", err)
	}

	c.printfln("Mount success.")

	return 0, nil
}

// handleOptions deals with options, erroring if options are missing, etc.
func (c *MountCommand) handleOptions() (int, error) {
	if c.Options.Name == "" || c.Options.LocalPath == "" {
		c.printfln("Mount Name and LocalPath are required options.")
		c.Help()
		return 1, errors.New("Not enough arguments")
	}

	if c.Options.PrefetchInterval == 0 {
		c.Options.PrefetchInterval = 10
		c.Log.Info("Setting interval to default, %d", c.Options.PrefetchInterval)
	}

	// temporarily disable watcher
	// TODO: Re-enable
	c.Options.NoWatch = true
	c.Log.Warning("Manually disabling Watcher")

	if c.Options.NoPrefetchMeta && c.Options.PrefetchAll {
		c.printfln(PrefetchAllAndMetaTogether)
		return 1, fmt.Errorf("noPrefetchMeta and prefetchAll were both supplied")
	}

	// allow scp like declaration, ie `<machine name>:/path/to/remote`
	if strings.Contains(c.Options.Name, ":") {
		names := strings.Split(c.Options.Name, ":")
		c.Options.Name, c.Options.RemotePath = names[0], names[1]
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

// setupKlient creates and dials our Kite interface *only* if it is nil. If it is
// not nil, someone else gave a kite to this Command, and it is expected to be
// dialed and working.
func (c *MountCommand) setupKlient() (int, error) {
	// if c.klient isnt nil, don't overrite it. Another command may have provided
	// a pre-dialed klient.
	if c.Klient != nil {
		return 0, nil
	}

	k, err := NewDialedKlient(c.KlientOptions)
	if err != nil {
		return 1, fmt.Errorf("Failed to get working Klient instance")
	}

	c.Klient = k

	return 0, nil
}

// prefetchAll
func (c *MountCommand) prefetchAll() error {
	c.Log.Info("Executing prefetch...")
	c.printfln("Prefetch All feature is currently in beta.")

	//func mountCommandPrefetchAll(stdout io.Writer, k Transport, getUser userGetter, machineName, localPath, remotePath string, interval int) int {
	homeDir, err := c.homeDirGetter()
	if err != nil {
		// Using internal error here, because a list error would be confusing to the
		// user.
		c.printfln(GenericInternalError)
		return fmt.Errorf("Failed to get OS User. err:%s", err)
	}

	// TODO: Use the ssh.Command's implementation of this logic, once ssh.Command is
	// moved to this new struct setup.
	sshKey := &SSHKey{
		KeyPath: path.Join(homeDir, c.Options.SSHDefaultKeyDir),
		KeyName: c.Options.SSHDefaultKeyName,
		Klient:  c.Klient,
	}

	if !sshKey.KeysExist() {
		// TODO: Fix this environment leak.
		util.MustConfirm("The 'prefetchAll' flag needs to create public/private rsa key pair. Continue? [Y|n]")
	}

	remoteUsername, err := sshKey.GetUsername(c.Options.Name)
	if err != nil {
		c.printfln(FailedGetSSHKey)
		return fmt.Errorf("Error getting remote username. err:%s", err)
	}

	if err := sshKey.PrepareForSSH(c.Options.Name); err != nil {
		if strings.Contains(err.Error(), "user: unknown user") {
			c.printfln(CannotSSHManaged)
			return fmt.Errorf("Cannot ssh into managed machines. err:%s", err)
		}

		c.printfln(FailedGetSSHKey)
		return fmt.Errorf("Error getting ssh key. err:%s", err)
	}

	c.printfln("Prefetching remote path...")

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

	cacheReq := req.Cache{
		Name:              c.Options.Name,
		LocalPath:         getCachePath(c.Options.Name),
		RemotePath:        c.Options.RemotePath,
		Interval:          time.Duration(c.Options.PrefetchInterval) * time.Second,
		Username:          remoteUsername,
		SSHAuthSock:       util.GetEnvByKey(os.Environ(), "SSH_AUTH_SOCK"),
		SSHPrivateKeyPath: sshKey.PrivateKeyPath(),
	}

	if err := c.Klient.RemoteCache(cacheReq, cacheProgressCallback); err != nil {
		c.printfln(
			defaultHealthChecker.CheckAllFailureOrMessagef(FailedPrefetchFolder),
		)
		return fmt.Errorf("remote.cacheFolder returned an error. err:%s", err)
	}

	if err := <-doneErr; err != nil {
		c.printfln(
			defaultHealthChecker.CheckAllFailureOrMessagef(FailedPrefetchFolder),
		)
		return fmt.Errorf(
			"remote.cacheFolder progress callback returned an error. err:%s", err,
		)
	}

	bar.FinishPrint("Prefetching complete.")

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

		default:
			// catch any remaining errors
			c.printfln(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToMount))
			return fmt.Errorf("Error mounting directory. err:%s", err)
		}
	}

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
