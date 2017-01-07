package machine

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"koding/klient/machine/machinegroup"
	"koding/klientctl/klient"

	"github.com/koding/logging"
)

// MountOptions stores options for `machine mount` call.
type MountOptions struct {
	Identifier string // Machine identifier.
	Path       string // Machine local path - absolute and cleaned.
	RemotePath string // Remote machine path - raw format.
	Log        logging.Logger
}

// Mount creates synchronized directory between remote and local machines.
func Mount(options *MountOptions) (err error) {
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
	//
	// TODO(ppknap): this is copied from klientctl old list and will be reworked.
	k, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating klient:", err)
		return err
	}

	if err := k.Dial(); err != nil {
		fmt.Fprintln(os.Stderr, "Error dialing klient:", err)
		return err
	}

	idReq := machinegroup.IDRequest{
		Identifier: options.Identifier,
	}
	idRaw, err := k.Tell("machine.id", idReq)
	if err != nil {
		return err
	}
	idRes := machinegroup.IDResponse{}
	if err := idRaw.Unmarshal(&idRes); err != nil {
		return err
	}

	return nil
}

// mountPointDirectory checks and prepares local directory for mounting.
// Returned clean function can be used to remove resources in case of other
// mounting errors.
func mountPointDirectory(path string) (clean func(), err error) {
	switch info, err := os.Stat(path); {
	case os.IsNotExist(path):
		// Create a new directory. In case of errors clean will remove it.
		if err := os.MkdirAll(path, 0755); err != nil {
			return nil, fmt.Errorf("cannot create destination directory: %s", err)
		}
		return func() { os.RemoveAll(path) }, nil
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
	clean = func() { removeContent(path) }

	return clean, nil

}

// removeContent removes all files inside provided path but not path itself.
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

	return nil
}
