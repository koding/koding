package main

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/codegangsta/cli"
)

// ServiceUninstaller is used to reduce the testable size of the Service, easing
// mocking.
type ServiceUninstaller interface {
	// Uninstall the given service
	Uninstall() error
}

// Uninstall is a configurable struct which handles the uninstall
// logic for the UninstallCommand, and making it entirely configurable
// and thus testable.
type Uninstall struct {
	// The uninstaller to call.
	ServiceUninstaller ServiceUninstaller

	// The public facing klient name (not filename).
	KlientName string

	// The public facing klient name (not filename).
	KlientctlName string

	// Kite key directory to remove, if empty
	KiteKeyDirectory string

	// The kite.key filename to remove within the KiteHome
	KiteKeyFilename string

	// The full path of the klientctl binary to be removed. Note that the directory
	// is not removed, as it is often a PATH complaint directory and should likely
	// be left intact.
	KlientctlPath string

	// The parent *non-removable* directory for the KlientDirectory. Since Klient
	// is often stored in nested directories, the KlientParentDirectory is the first
	// directory that that is not removed. Example:
	//
	// KlientBin		         == klient
	// KlientDirectory       == kite/klient
	// KlientParentDirectory == /opt
	// FullKlientBinPath     == /opt/kite/klient/klient
	//
	// See also: Uninstall.RemoveKlientDirectories()
	KlientParentDirectory string

	// *All* of the directories of the klient binary to be removed, if empty. It's
	// important to note that every directory in this path will be removed. Please
	// see KlientParentDirectory for additional details.
	//
	// Example value:
	//
	//     kite/klient
	KlientDirectory string

	// the Klient binary filename to be removed.
	KlientFilename string

	// The klient.sh filename to be removed.
	KlientshFilename string

	// remover is a remove func, which can be used to play safe for testing. Typically
	// equals os.Remove.
	remover func(string) error
}

// Uninstall actually runs the uninstall process, configured by the structs fields,
// and implemented by all the individual uninstall methods.
//
// Note that Uninstall cleans up the directories if empty, but does not print
// warning messages about this. This is to avoid spam, as one failure to remove a
// bin can end up with multiple warnings, creating a bad UX.
func (u *Uninstall) Uninstall() (string, int) {
	if err := u.ServiceUninstaller.Uninstall(); err != nil {
		return fmt.Sprintf("Error uninstalling %s: '%s'\n", KlientName, err), 1
	}

	// Since most issues faced during file removal are not critical errors,
	// we can compile a collection of warnings and print them to the user.
	warnings := []string{}

	// Remove the kitekey
	if p := filepath.Join(u.KiteKeyDirectory, u.KiteKeyFilename); p != "" {
		if err := os.Remove(p); err != nil {
			warnings = append(warnings, fmt.Sprintf(
				"Warning: Failed to remove authorization file. This is not a critical issue.\n",
			))
		}
	}

	// Remove the klient/klient.sh files
	if err := u.RemoveKlientFiles(); err != nil {
		warnings = append(warnings, fmt.Sprintf(
			"Warning: Failed to remove %s files. This is not a critical issue.\n",
			u.KlientName,
		))
	}

	// Remove the klient directories
	//
	// Note that we're ignoring any errors in removing the directories to avoid
	// spamming the user with warnings.
	u.RemoveKlientDirectories()

	// Remove the klientctl binary itself.
	// (The current binary is removing itself.. So emo...)
	if err := u.RemoveKlientctl(); err != nil {
		warnings = append(warnings, fmt.Sprintf(
			"Warning: Failed to remove %s binary. This is not a critical issue.\n",
			u.KlientctlName,
		))
	}

	if len(warnings) != 0 {
		return fmt.Sprintf(
			"Successfully uninstalled %s, with warnings:\n%s",
			u.KlientName, strings.Join(warnings, "\n"),
		), 0
	}

	return fmt.Sprintf("Successfully uninstalled %s\n", KlientName), 0
}

// UninstallCommand configures the Uninstall struct and calls it based on the
// given codegangsta/cli context.
//
// TODO: remove all artifacts, ie bolt db, ssh keys, kd etc.
func UninstallCommand(c *cli.Context) (string, int) {
	s, err := newService()
	if err != nil {
		return fmt.Sprintf("Error identifying service %s: '%s'\n", KlientName, err), 1
	}

	uninstaller := &Uninstall{
		ServiceUninstaller: s,
		KlientName:         KlientName,
		KlientctlName:      Name,
		KiteKeyDirectory:   KiteHome,
		// TODO: Store the kite.key path somewhere
		KiteKeyFilename: "kite.key",
		KlientctlPath:   filepath.Join(KlientctlDirectory, KlientctlBinName),
		// TODO: Store the klient directory structure(s) somewhere
		KlientParentDirectory: "/opt",
		KlientDirectory:       "kite/klient",
		KlientFilename:        "klient",
		KlientshFilename:      "klient.sh",
		remover:               os.Remove,
	}

	return uninstaller.Uninstall()
}

// RemoveKiteKey removes the kite key and kitekeydirectory
func (u *Uninstall) RemoveKiteKey() error {
	// Remove the kitekey
	if u.KiteKeyDirectory == "" {
		return errors.New("KiteKeyDirectory cannot be empty")
	}

	if u.KiteKeyFilename == "" {
		return errors.New("KiteKeyFilename cannot be empty")
	}

	p := filepath.Join(u.KiteKeyDirectory, u.KiteKeyFilename)
	if err := os.Remove(p); err != nil {
		return err
	}

	// Remove kiteHome, if empty. Do not return failed folder removals for a good ux.
	//
	// As with most file operations, checking the state and then acting is an
	// error prone and non-atomic endevour. As such, we're just removing the
	// directory here, and if it is non-empty this operation will fail.
	os.Remove(u.KiteKeyDirectory)

	return nil
}

// RemoveKlientFiles removes the klient bin, klient.sh, but not the klient
// directories. For directories, see Uninstall.RemoveKlientDirectories
func (u *Uninstall) RemoveKlientFiles() error {
	if u.KlientParentDirectory == "" {
		return errors.New("KlientParentDirectory cannot be empty")
	}

	if u.KlientDirectory == "" {
		return errors.New("KlientDirectory cannot be empty")
	}

	if u.KlientFilename == "" {
		return errors.New("KlientFilename cannot be empty")
	}

	if u.KlientshFilename == "" {
		return errors.New("KlientshFilename cannot be empty")
	}

	// Remove klient bin
	klientPath := filepath.Join(u.KlientDirectory, u.KlientDirectory)
	if err := os.Remove(klientPath); err != nil {
		return err
	}

	// Remove klient.sh
	klientshPath := filepath.Join(u.KlientDirectory, u.KlientshFilename)
	if err := os.Remove(klientshPath); err != nil {
		return err
	}

	return nil
}

// RemoveKlientDirectories removes the klient directories recursively, up until and
// not including the Uninstall.KlientParentDirectory. As an example:
//
// KlientBin		         == klient
// KlientDirectory       == kite/klient
// KlientParentDirectory == /opt
// FullKlientBinPath     == /opt/kite/klient/klient
//
// In the above, /opt/kite/klient and /opt/kite would be removed, but not
// /opt. If /opt/kite/klient is not empty, nothing is removed.
func (u *Uninstall) RemoveKlientDirectories() error {
	if u.KlientDirectory == "" {
		return errors.New("KlientDirectory cannot be empty")
	}

	if u.KlientParentDirectory == "" {
		return errors.New("KlientParentDirectory cannot be empty")
	}

	if filepath.IsAbs(u.KlientDirectory) {
		return errors.New("Cannot use absolute path directory")
	}

	// Remove the klient directories repeatedly up until the parent.
	//
	// Note that the "." check is because Dir will return the dot (current directory)
	// when there are no other dirs to return. Example:
	//
	// 		filepath.Dir("foo/bar/baz") // foo/bar
	// 		filepath.Dir("foo/bar") 		// foo
	// 		filepath.Dir("foo") 				// .
	for p := u.KlientDirectory; p != "."; p = filepath.Dir(p) {
		rmP := filepath.Join(u.KlientParentDirectory, p)

		// Just to be extra safe, since we're loop removing, lets confirm that it's
		// not the parent dir. In multiple forms.
		if rmP == u.KlientParentDirectory || filepath.Clean(rmP) == filepath.Clean(u.KlientParentDirectory) {
			return errors.New("Directory to be removed equalled the KlientParentDirectory")
		}

		// If there is any error, return it. Generally we don't care about removal
		// errors, but if anything fails we can't do anything with future parent dirs,
		// so there's nothing to be done.
		if err := os.Remove(rmP); err != nil {
			return err
		}
	}

	return nil
}

// RemoveKlientctl removes the klient binary
// (The current binary is removing itself.. So emo...)
func (u *Uninstall) RemoveKlientctl() error {
	if u.KlientctlPath == "" {
		return errors.New("KlientctlPath cannot be empty")
	}

	return os.Remove(u.KlientctlPath)
}
