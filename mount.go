package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"os/user"
	"path"
	"path/filepath"
	"strings"
	"time"

	"github.com/cheggaaa/pb"
	"github.com/codegangsta/cli"
	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/klient/remote/req"
	"github.com/koding/klientctl/klientctlerrors"
	"github.com/koding/klientctl/util"
)

type userGetter func() (*user.User, error)

// MountCommand mounts a folder on remote machine to local folder by machine
// name.
func MountCommand(c *cli.Context) int {
	if len(c.Args()) != 2 {
		cli.ShowCommandHelp(c, "mount")
		return 1
	}

	var (
		name             = c.Args()[0]
		localPath        = c.Args()[1]
		remotePath       = c.String("remotepath")     // note the lowercase of all chars
		noIgnore         = c.Bool("noignore")         // note the lowercase of all chars
		noPrefetchMeta   = c.Bool("noprefetch-meta")  // note the lowercase of all chars
		noWatch          = c.Bool("nowatch")          // note the lowercase of all chars
		prefetchAll      = c.Bool("prefetch-all")     // note the lowercase of all chars
		prefetchInterval = c.Int("prefetch-interval") // note the lowercase of all chars
	)

	if prefetchInterval == 0 {
		prefetchInterval = 10
		log.Infof("Setting interval to default, %d", prefetchInterval)
	}

	// temporarily disable watcher
	noWatch = true

	if noPrefetchMeta && prefetchAll {
		log.Errorf("noPrefetchMeta and prefetchAll were both supplied")
		fmt.Println(PrefetchAllAndMetaTogether)
		return 1
	}

	// allow scp like declaration, ie `<machine name>:/path/to/remote`
	if strings.Contains(name, ":") {
		names := strings.Split(name, ":")
		name, remotePath = names[0], names[1]
	}

	// send absolute local path to klient unless local path is empty
	if strings.TrimSpace(localPath) != "" {
		absoluteLocalPath, err := filepath.Abs(localPath)
		if err == nil {
			localPath = absoluteLocalPath
		}
	}

	// remove trailing slashes in remote argument
	if remotePath != "" {
		remotePath = path.Clean(remotePath)
	}

	// Ask the user if they want the localPath created, if it does not exist.
	if err := askToCreate(localPath, os.Stdin, os.Stdout); err != nil {
		// If the error is that the user cancelled, just return
		if err == klientctlerrors.ErrUserCancelled {
			fmt.Println(CannotMountDirNotExist)
			return 0
		}

		log.Errorf("Error creating local mount path. err:%s", err)
		fmt.Println(FailedToCreateMountDir)
		return 1
	}

	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		log.Errorf("Error creating klient client. err:%s", err)
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(GenericInternalError))
		return 1
	}

	if err := k.Dial(); err != nil {
		log.Errorf("Error dialing klient client. err:%s", err)
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(GenericInternalError))
		return 1
	}

	infos, err := getListOfMachines(k)
	if err != nil {
		log.Errorf("Failed to get list of machines on mount. err:%s", err)
		// Using internal error here, because a list error would be confusing to the
		// user.
		fmt.Println(GenericInternalError)
		return 1
	}

	// allow for shortcuts when specifying name
	for _, info := range infos {
		if strings.HasPrefix(info.VMName, name) {
			name = info.VMName
		}
	}

	mountRequest := req.MountFolder{
		Name:           name,
		LocalPath:      localPath,
		NoIgnore:       noIgnore,
		NoPrefetchMeta: noPrefetchMeta,
		PrefetchAll:    prefetchAll,
		NoWatch:        noWatch,
		CachePath:      getCachePath(localPath),
	}

	// RemotePath is optional
	if remotePath != "" {
		mountRequest.RemotePath = remotePath
	}

	if prefetchAll {
		if exit := mountCommandPrefetchAll(os.Stdout, k, user.Current, name, localPath, remotePath, prefetchInterval); exit != 0 {
			return exit
		}
	}

	resp, err := k.Tell("remote.mountFolder", mountRequest)
	if err != nil {
		switch {
		case klientctlerrors.IsExistingMountErr(err):
			util.MustConfirm("This folder is already mounted. Remount? [Y|n]")

			// unmount using mount path
			if err := unmount(k, "", localPath); err != nil {
				log.Errorf("Error unmounting (remounting). err:%s", err)
				fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToUnmount))
				return 1
			}

			resp, err = k.Tell("remote.mountFolder", mountRequest)
			if err != nil {
				log.Errorf("Error mounting (remounting). err:%s", err)
				fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToMount))
				return 1
			}

		case klientctlerrors.IsDialFailedErr(err):
			log.Errorf("Error dialing remote klient. err:%s", err)
			fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedDialingRemote))
			return 1

		default:
			// catch any remaining errors
			log.Errorf("Error mounting directory. err:%s", err)
			fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToMount))
			return 1
		}
	}

	// catch errors other than klientctlerrors.IsExistingMountErr
	if err != nil {
		log.Errorf("Error mounting directory. err:%s", err)
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(FailedToMount))
		return 1
	}

	// response can be nil even when there's no err
	if resp != nil {
		var warning string
		// TODO: Ignore the nil unmarshal error, but log others.
		if err := resp.Unmarshal(&warning); err != nil {
			return 0
		}

		if len(warning) > 0 {
			fmt.Printf("Warning: %s\n", warning)
		}
	}

	if err := Lock(localPath, name); err != nil {
		log.Errorf("Error locking. err:%s", err)
		fmt.Println(FailedToLockMount)
		return 1
	}

	fmt.Println("Mount success.")

	return 0
}

// TODO: A temporary function which will be converted to a private method once
// MountCommand is converted to a struct based CLI Interface. Once it's a private
// method, we won't have to pass in so much via args.
func mountCommandPrefetchAll(stdout io.Writer, k Transport, getUser userGetter, machineName, localPath, remotePath string, interval int) int {
	usr, err := getUser()
	if err != nil {
		log.Errorf("Failed to get OS User. err:%s", err)
		// Using internal error here, because a list error would be confusing to the
		// user.
		fmt.Println(GenericInternalError)
		return 1
	}

	sshKey := &SSHKey{
		KeyPath:   path.Join(usr.HomeDir, SSHDefaultKeyDir),
		KeyName:   SSHDefaultKeyName,
		Transport: k,
	}

	if !sshKey.KeysExist() {
		util.MustConfirm("The 'prefetchAll' flag needs to create public/private rsa key pair. Continue? [Y|n]")
	}

	remoteUsername, err := sshKey.GetUsername(machineName)
	if err != nil {
		log.Errorf("Error getting remote username. err:%s", err)
		fmt.Println(FailedGetSSHKey)
		return 1
	}

	if err := sshKey.PrepareForSSH(machineName); err != nil {
		if strings.Contains(err.Error(), "user: unknown user") {
			log.Errorf("Cannot ssh into managed machines. err:%s", err)
			fmt.Println(CannotSSHManaged)
			return 1
		}

		log.Errorf("Error getting ssh key. err:%s", err)
		fmt.Println(FailedGetSSHKey)
		return 1
	}

	fmt.Println("Prefetching remote path...")

	// doneErr is used to wait until the cache progress is done, and also send
	// any error encountered. We simply send nil if there is no error.
	doneErr := make(chan error)

	// The creation of the pb objection presents a CLI progress bar to the user.
	var bar *pb.ProgressBar

	// The callback, used to update the progress bar as remote.cache downloads
	cacheProgressCallback := func(par *dnode.Partial) {
		// initialize bar if nil; do it in callback so the user isn't shown an
		// empty bar while waiting for first entry
		if bar == nil {
			bar = pb.StartNew(100)
			bar.SetMaxWidth(100)
		}

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
			log.Errorf("remote.cacheFolder progress callback returned an error. err:%s", err)
			fmt.Println(
				defaultHealthChecker.CheckAllFailureOrMessagef(FailedPrefetchFolder),
			)
		}

		bar.Set(p.Progress)

		// TODO: Disable the callback here, so that it's impossible to double call
		// the progress after competion - to avoid weird/bad UX and errors.
		if p.Progress == 100 {
			doneErr <- nil
		}
	}

	rReq := req.Cache{
		Name:              machineName,
		LocalPath:         getCachePath(localPath),
		RemotePath:        remotePath,
		Interval:          time.Duration(interval) * time.Second,
		Username:          remoteUsername,
		SSHAuthSock:       util.GetEnvByKey(os.Environ(), "SSH_AUTH_SOCK"),
		SSHPrivateKeyPath: sshKey.PrivateKeyPath(),
	}

	cacheReq := struct {
		req.Cache
		Progress dnode.Function `json:"progress"`
	}{
		Cache:    rReq,
		Progress: dnode.Callback(cacheProgressCallback),
	}

	if _, err := k.Tell("remote.cacheFolder", cacheReq); err != nil {
		log.Errorf("remote.cacheFolder returned an error. err:%s", err)
		fmt.Println(
			defaultHealthChecker.CheckAllFailureOrMessagef(FailedPrefetchFolder),
		)
		return 1
	}

	if err := <-doneErr; err != nil {
		log.Errorf(
			"remote.cacheFolder progress callback returned an error. err:%s", err,
		)
		fmt.Println(
			defaultHealthChecker.CheckAllFailureOrMessagef(FailedPrefetchFolder),
		)
	}

	bar.FinishPrint("Prefetching complete.")

	return 0
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

	return os.Mkdir(p, 0655)
}

func getCachePath(path string) string {
	// TODO: Put the cache somewhere meaningful
	return fmt.Sprintf("%s.cache", path)
}
