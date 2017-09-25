package machine

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/machinegroup"
	"koding/klient/machine/mount"
	"koding/klient/machine/mount/prefetch"
	"koding/klientctl/helper"

	humanize "github.com/dustin/go-humanize"
	"github.com/koding/kite/dnode"
)

// MountOptions stores options for `machine mount` call.
type MountOptions struct {
	Identifier string // Machine identifier.
	Path       string // Machine local path - absolute and cleaned.
	RemotePath string // Remote machine path - raw format.

	AskList func(is, ds []string) (string, error) // Ask for multiple choices.
}

func (c *Client) mountPoint(id machine.ID) (string, error) {
	m, err := c.machine(id)
	if err != nil {
		return "", err
	}

	return filepath.Join(c.konfig().Mount.Home, m.Label), nil
}

// Mount synchronizes directories between remote and local machines.
func (c *Client) Mount(options *MountOptions) (err error) {
	c.init()

	if options == nil {
		return errors.New("invalid nil options")
	}

	// Translate identifier to machine ID.
	id, err := c.getMachineID(options.Identifier, options.AskList)
	if err != nil {
		return err
	}

	if options.Path == "" {
		if options.Path, err = c.mountPoint(id); err != nil {
			return err
		}
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

	fmt.Fprintf(c.stream().Out(), "Mounting to %s directory.\nChecking remote path...\n", options.Path)

	m := mount.Mount{
		Path:       options.Path,
		RemotePath: options.RemotePath,
	}

	// First head the remote machine directory in order to get basic mount info.
	headMountReq := &machinegroup.HeadMountRequest{
		MountRequest: machinegroup.MountRequest{
			ID:    id,
			Mount: m,
		},
	}
	var headMountRes machinegroup.HeadMountResponse

	if err = c.klient().Call("machine.mount.head", headMountReq, &headMountRes); err != nil {
		return err
	}

	// Remote directory is already mounted to this machine.
	//
	// TODO: ask user if she wants to create another mount or stop the process.
	if headMountRes.ExistMountID != "" {
		fmt.Fprintf(c.stream().Out(), "Remote directory %s is already mounted by: %s\n",
			headMountRes.AbsRemotePath, headMountRes.ExistMountID)

		clean()
		return nil
	}

	fmt.Fprintf(c.stream().Out(), "Mounted remote directory %s has %d file(s) of total size %s\n",
		headMountRes.AbsRemotePath, headMountRes.AllCount, humanize.IBytes(uint64(headMountRes.AllDiskSize)))

	// TODO: ask user if she wants to continue.

	m.RemotePath = headMountRes.AbsRemotePath
	fmt.Fprintf(c.stream().Out(), "Initializing mount %s...\n", m)

	// Create mount.
	addMountReq := &machinegroup.AddMountRequest{
		MountRequest: machinegroup.MountRequest{
			ID:    id,
			Mount: m,
		},
		Strategies: prefetch.DefaultStrategy.Available(),
	}
	var addMountRes machinegroup.AddMountResponse
	if err = c.klient().Call("machine.mount.add", addMountReq, &addMountRes); err != nil {
		return err
	}
	defer func() {
		// Remove mount when post mount operations fail.
		if err != nil {
			umountReq := &machinegroup.UmountRequest{
				Identifier: string(addMountRes.MountID),
			}
			_ = c.klient().Call("machine.umount", umountReq, nil)
		}
	}()

	// Prefetch files.
	_, _, privPath, err := sshGetKeyPath()
	if err == nil {
		err = addMountRes.Prefetch.Run(os.Stdout, prefetch.DefaultStrategy, privPath)
	}
	if err != nil {
		fmt.Fprintf(c.stream().Err(), "Cannot prefetch mount files: %s\n", err)
		c.stream().Log().Error("Prefetching failed: %s\n", err)
		if exitErr, ok := err.(*exec.ExitError); ok {
			c.stream().Log().Error("Output: %q", exitErr.Stderr)
		}

		return err
	}

	// Rescan cache folder in order to update index.
	upIdxMountReq := &machinegroup.UpdateIndexRequest{
		MountID: addMountRes.MountID,
	}
	var upIdxMountRes machinegroup.UpdateIndexResponse
	if err = c.klient().Call("machine.mount.updateIndex", upIdxMountReq, &upIdxMountRes); err != nil {
		return err
	}

	fmt.Fprintf(c.stream().Out(), "Created mount with ID: %s\n", addMountRes.MountID)

	// Best-effort attempt of making the remote vm do not
	// turn off after 1h.
	_ = c.setAlwaysOn(id, "true")

	return nil
}

// ListMountOptions stores options for `machine mount list` call.
type ListMountOptions struct {
	ID      string // Machine ID - optional.
	MountID string // Mount ID - optional.
}

// ListMount lists local mounts that are known to a klient.
func (c *Client) ListMount(options *ListMountOptions) (map[string][]mount.Info, error) {
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

// MountIdentifiersOptions stores options for "machine mount identifiers" call.
type MountIdentifiersOptions struct {
	MountIds  bool
	BasePaths bool
}

// MountIdentifiers returns cached mounts identifiers.
func (c *Client) MountIdentifiers(options *MountIdentifiersOptions) ([]string, error) {
	mountIdentifiersReq := &machinegroup.MountIdentifierListRequest{
		MountIds:  options.MountIds,
		BasePaths: options.BasePaths,
	}
	var mountIdentifiersRes machinegroup.MountIdentifierListResponse

	if err := c.klient().Call("machine.mount.identifier.list", mountIdentifiersReq, &mountIdentifiersRes); err != nil {
		return nil, err
	}

	return mountIdentifiersRes.Identifiers, nil
}

// InspectMountOptions stores options for `machine mount inspect` call.
type InspectMountOptions struct {
	Identifier string // Mount identifier.
	Sync       bool   // Get syncing history.
	Tree       bool   // Show index tree.
	Filesystem bool   // Check and report filesystem consistency.
}

// InspectMount inspects provided mount.
func (c *Client) InspectMount(options *InspectMountOptions) (machinegroup.InspectMountResponse, error) {
	var inspectMountRes machinegroup.InspectMountResponse
	if options == nil {
		return inspectMountRes, errors.New("invalid nil options")
	}

	// Inspect mount.
	inspectMountReq := &machinegroup.InspectMountRequest{
		Identifier: options.Identifier,
		Sync:       options.Sync,
		Tree:       options.Tree,
		Filesystem: options.Filesystem,
	}

	err := c.klient().Call("machine.mount.inspect", inspectMountReq, &inspectMountRes)
	return inspectMountRes, err
}

// UmountOptions stores options for `machine umount` call.
type UmountOptions struct {
	Identifiers []string // Mount identifiers.
	Force       bool     // Disable interactive mode.
	All         bool     // Unmount all.
}

// Umount removes existing mount.
func (c *Client) Umount(options *UmountOptions) (err error) {
	if options == nil {
		return errors.New("invalid nil options")
	}

	// Get all mounts if all option is set.
	identifiers := options.Identifiers
	if options.All {
		mids, err := c.allMounts()
		if err != nil {
			return err
		}
		identifiers = mids
	}

	// If there are no mounts we return nil.
	if len(identifiers) == 0 {
		fmt.Fprintf(c.stream().Out(), "There is nothing to unmount\n")
		return nil
	}

	// Do not be too verbose.
	promptSuffix := strings.Join(identifiers, ", ")
	if n := len(identifiers); n > 2 {
		promptSuffix = strconv.Itoa(n) + " mounts"
	}

	fmt.Fprintf(c.stream().Out(), "Unmounting %s...\n", promptSuffix)

	var yn = "yes"
	// TODO(ppknap): remove second condition when atom package implements "force" flag.
	if !options.Force && len(identifiers) > 1 {
		yn, err = helper.Fask(c.stream().In(), c.stream().Out(),
			"This operation will remove all cached data. Do you want to continue [y/N]: ")
		if err != nil {
			return err
		}
	}

	if yn = strings.ToLower(yn); yn != "yes" && yn != "y" {
		return errors.New("aborted by user")
	}

	// Remove mounts.
	for _, identifier := range identifiers {
		umountReq := &machinegroup.UmountRequest{
			Identifier: identifier,
		}
		var umountRes machinegroup.UmountResponse

		err := c.klient().Call("machine.umount", umountReq, &umountRes)
		if err != nil {
			fmt.Fprintf(c.stream().Out(), "Cannot unmount %s (ID: %s): %s\n", umountRes.Mount, umountRes.MountID, err)
		} else {
			fmt.Fprintf(c.stream().Out(), "Successfully unmounted %s (ID: %s)\n", umountRes.Mount, umountRes.MountID)
		}
	}

	return nil
}

// SyncMountOptions stores options for `machine mount sync` call.
type SyncMountOptions struct {
	Identifier string
	Pause      bool
	Resume     bool
	Timeout    time.Duration
}

// SyncMount allows to configure mount synchronization settings and provides
// way to ensure that all synchronization events are processed.
func (c *Client) SyncMount(opts *SyncMountOptions) error {
	// Get mount ID from provided identifer.
	mountIDReq := &machinegroup.MountIDRequest{
		Identifier: opts.Identifier,
	}
	var mountIDRes machinegroup.MountIDResponse
	if err := c.klient().Call("machine.mount.id", mountIDReq, &mountIDRes); err != nil {
		return err
	}

	// Set mount synchronization settings.
	manageMountReq := &machinegroup.ManageMountRequest{
		MountID: mountIDRes.MountID,
		Pause:   opts.Pause,
		Resume:  opts.Resume,
	}
	var manageMountRes machinegroup.ManageMountResponse
	if err := c.klient().Call("machine.mount.manage", manageMountReq, &manageMountRes); err != nil {
		return err
	}

	if opts.Pause || opts.Resume {
		return nil
	}

	// Wait for idle synchronization status.
	ch := make(chan bool)
	req := &machinegroup.WaitIdleRequest{
		MountID: mountIDRes.MountID,
		Timeout: opts.Timeout,
		Done: dnode.Callback(func(r *dnode.Partial) {
			ch <- r.One().MustBool()
		}),
	}

	if err := c.klient().Call("machine.mount.waitIdle", req, nil); err != nil {
		return err
	}

	// Release read-only access before long-running operation.
	_ = c.kloud().Cache().CloseRead()

	if !<-ch {
		if req.Timeout != 0 {
			return fmt.Errorf("waiting for mount to synchronize has timed out after %s", req.Timeout)
		}
		return fmt.Errorf("waiting for mount to synchronize has timed out")
	}

	return nil
}

func (c *Client) allMounts() (mids []string, err error) {
	var (
		listMountReq machinegroup.ListMountRequest
		listMountRes machinegroup.ListMountResponse
	)

	if err := c.klient().Call("machine.mount.list", listMountReq, &listMountRes); err != nil {
		return nil, err
	}

	for _, infos := range listMountRes.Mounts {
		for _, info := range infos {
			mids = append(mids, string(info.ID))
		}
	}

	return mids, nil
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
func ListMount(opts *ListMountOptions) (map[string][]mount.Info, error) {
	return DefaultClient.ListMount(opts)
}

// SyncMount manages mount synchronization.
func SyncMount(opts *SyncMountOptions) error { return DefaultClient.SyncMount(opts) }

// MountIdentifiers returns cached mount identifiers using DefaultClient.
func MountIdentifiers(opts *MountIdentifiersOptions) ([]string, error) {
	return DefaultClient.MountIdentifiers(opts)
}

// InspectMount inspects existing mount using DefaultClient.
func InspectMount(opts *InspectMountOptions) (machinegroup.InspectMountResponse, error) {
	return DefaultClient.InspectMount(opts)
}

// Umount removes existing mount using DefaultClient.
func Umount(opts *UmountOptions) error { return DefaultClient.Umount(opts) }
