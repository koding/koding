package machine

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/sync"
	"koding/klient/machine/mount/sync/prefetch"

	"github.com/dustin/go-humanize"
	"github.com/koding/logging"
)

// CpOptions stores options for `machine cp` call.
type CpOptions struct {
	Download        string // Set to true when download from remote.
	Identifier      string // Machine identifier.
	SourcePath      string // Data source.
	DestinationPath string // Data destination.
	Log             logging.Logger
}

// Cp transfers file(s) between remote and local machine.
func (c *Client) Cp(options *MountOptions) (err error) {
	if options == nil {
		return errors.New("invalid nil options")
	}

	// Create and check mount point directory.
	clean, err := mountPointDirectory(options.Path)
	if err != nil {
		return err
	}
	defer func() {
		if err != nil {
			clean()
		}
	}()

	// Translate identifier to machine ID.
	idReq := &machinegroup.IDRequest{
		Identifier: options.Identifier,
	}
	var idRes machinegroup.IDResponse

	if err := c.klient().Call("machine.id", idReq, &idRes); err != nil {
		return err
	}

	fmt.Fprintf(os.Stdout, "Mounting to %s directory.\nChecking remote path...\n", options.Path)

	m := mount.Mount{
		Path:       options.Path,
		RemotePath: options.RemotePath,
	}

	// First head the remote machine directory in order to get basic mount info.
	headMountReq := &machinegroup.HeadMountRequest{
		MountRequest: machinegroup.MountRequest{
			ID:    idRes.ID,
			Mount: m,
		},
	}
	var headMountRes machinegroup.HeadMountResponse

	if err := c.klient().Call("machine.mount.head", headMountReq, &headMountRes); err != nil {
		return err
	}

	// Remote directory is already mounted to this machine.
	//
	// TODO: ask user if she wants to create another mount or stop the process.
	if headMountRes.ExistMountID != "" {
		fmt.Fprintf(os.Stdout, "Remote directory %s is already mounted by: %s\n",
			headMountRes.AbsRemotePath, headMountRes.ExistMountID)

		clean()
		return nil
	}

	fmt.Fprintf(os.Stdout, "Mounted remote directory %s has %d file(s) of total size %s\n",
		headMountRes.AbsRemotePath, headMountRes.AllCount, humanize.IBytes(uint64(headMountRes.AllDiskSize)))

	// TODO: ask user if she wants to continue.

	m.RemotePath = headMountRes.AbsRemotePath
	fmt.Fprintf(os.Stdout, "Initializing mount %s...\n", m)

	// Create mount.
	addMountReq := &machinegroup.AddMountRequest{
		MountRequest: machinegroup.MountRequest{
			ID:    idRes.ID,
			Mount: m,
		},
		Strategies: prefetch.DefaultStrategy.Available(),
	}
	var addMountRes machinegroup.AddMountResponse

	if err := c.klient().Call("machine.mount.add", addMountReq, &addMountRes); err != nil {
		return err
	}

	// Prefetch files.
	_, _, privPath, err := sshGetKeyPath()
	if err == nil {
		err = addMountRes.Prefetch.Run(os.Stdout, prefetch.DefaultStrategy, privPath)
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "Cannot prefetch mount files: %s\n", err)
	}

	fmt.Fprintf(os.Stdout, "Created mount with ID: %s\n", addMountRes.MountID)
	return nil
}

// Cp transfers file(s) between remote and local machine using DefaultClient.
func Cp(opts *CpOptions) error { return DefaultClient.Cp(opts) }
