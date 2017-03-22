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

// MountOptions stores options for `machine mount` call.
type MountOptions struct {
	Identifier string // Machine identifier.
	Path       string // Machine local path - absolute and cleaned.
	RemotePath string // Remote machine path - raw format.
	Log        logging.Logger
}

// Mount synchronizes directories between remote and local machines.
func (c *Client) Mount(options *MountOptions) (err error) {
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

// ListMountOptions stores options for `machine mount list` call.
type ListMountOptions struct {
	ID      string // Machine ID - optional.
	MountID string // Mount ID - optional.
	Log     logging.Logger
}

// ListMount lists local mounts that are known to a klient.
func (c *Client) ListMount(options *ListMountOptions) (map[string][]sync.Info, error) {
	if options == nil {
		return nil, errors.New("invalid nil options")
	}

	// List mounts.
	listMountReq := &machinegroup.ListMountRequest{
		ID:      machine.ID(options.ID),
		MountID: mount.ID(options.MountID),
	}
	var listMountRes machinegroup.ListMountResponse

	if err := c.klient().Call("machine.mount.list", listMountReq, &listMountRes); err != nil {
		return nil, err
	}

	return listMountRes.Mounts, nil
}

// UmountOptions stores options for `machine umount` call.
type UmountOptions struct {
	Identifier string // Mount identifier.
	Log        logging.Logger
}

// Umount removes existing mount.
func (c *Client) Umount(options *UmountOptions) (err error) {
	if options == nil {
		return errors.New("invalid nil options")
	}

	// TODO: ask user to confirm unmounting.
	fmt.Fprintf(os.Stdout, "Unmounting %s...\n", options.Identifier)

	// Remove mount.
	umountReq := &machinegroup.UmountRequest{
		Identifier: options.Identifier,
	}
	var umountRes machinegroup.UmountResponse

	if err := c.klient().Call("machine.umount", umountReq, &umountRes); err != nil {
		return err
	}

	fmt.Fprintf(os.Stdout, "Successfully unmounted %s (ID: %s)\n",
		umountRes.Mount, umountRes.MountID)

	return nil
}

// mountPointDirectory checks and prepares local directory for mounting.
// Returned clean function can be used to remove resources in case of other
// mounting errors.
//
// NOTE: This logic will be moved to klient.
func mountPointDirectory(path string) (clean func(), err error) {
	switch info, err := os.Stat(path); {
	case os.IsNotExist(err):
		// Create a new directory.
		if err := os.MkdirAll(path, 0755); err != nil {
			return nil, fmt.Errorf("cannot create destination directory: %s", err)
		}
		return func() {
			os.RemoveAll(path)
		}, nil
	case err != nil:
		return nil, fmt.Errorf("cannot stat destination directory: %s", err)
	case !info.IsDir():
		return nil, fmt.Errorf("file %q is not a directory", path)

	}

	// Provided directory already exists. Check if it's empty.
	f, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("cannot open destination directory: %s", err)
	}
	defer f.Close()

	switch _, err = f.Readdirnames(1); err {
	case nil:
		return nil, errors.New("destination directory is not empty")
	case io.EOF:
	default:
		return nil, fmt.Errorf("destination directory error: %s", err)
	}
	clean = func() {
		removeContent(path)
	}

	return clean, nil

}

// removeContent removes all files inside provided path but not the path itself.
func removeContent(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	for {
		names, err := f.Readdirnames(100)
		if err != nil {
			return err
		}

		for _, name := range names {
			os.RemoveAll(filepath.Join(path, name)) // Ignore errors.
		}
	}
}

// Mount synchronizes directories between remote and local machines
// using DefaultClient.
func Mount(opts *MountOptions) error { return DefaultClient.Mount(opts) }

// ListMount lists local mounts that are known to a klient using DefaultClient.
func ListMount(opts *ListMountOptions) (map[string][]sync.Info, error) {
	return DefaultClient.ListMount(opts)
}

// Umount removes existing mount using DefaultClient.
func Umount(opts *UmountOptions) error { return DefaultClient.Umount(opts) }
