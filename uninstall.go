package main

import (
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
}

// Uninstall actually runs the uninstall process, configured by the structs fields.
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

	// Remove kiteHome, if empty
	if u.KiteKeyDirectory != "" {
		// As with most file operations, checking the state and then acting is an
		// error prone and non-atomic endevour. As such, we're just removing the
		// directory here, and if it is non-empty this operation will fail.
		os.Remove(u.KiteKeyDirectory)
	}

	// Remove the Klient bin
	if p := filepath.Join(u.KlientDirectory, u.KlientFilename); p != "" {
		if err := os.Remove(p); err != nil {
			warnings = append(warnings, fmt.Sprintf(
				"Warning: Failed to remove %s binary. This is not a critical issue.\n",
				u.KlientName,
			))
		}
	}

	// Remove klient.sh
	if p := filepath.Join(u.KlientDirectory, u.KlientshFilename); p != "" {
		if err := os.Remove(p); err != nil {
			warnings = append(warnings, fmt.Sprintf(
				"Warning: Failed to remove %s supporting file. This is not a critical issue.\n",
				u.KlientName,
			))
		}
	}

	// Remove the klient directories repeatedly up until the parent.
	//
	// Notes about the loops if checks:
	//
	//     // Ensures that u.KlientDirectory is not empty:
	//     p != ""
	//     // Ensures that the filepath is not root, in the case that
	//     // u.KlientDirectory == "/foo/bar" or "/opt/kite/klient"
	//     p != string(filepath.Separator)
	//     // Ensures that filepath is not the current directory, ie the end of the
	//     // KlientDirectories
	//     p != "."
	for p := u.KlientDirectory; p != "" && p != string(filepath.Separator) && p != "."; p = filepath.Dir(p) {
		delP := filepath.Join(u.KlientParentDirectory, p)

		// Just to be extra safe, since we're loop removing, lets confirm that it's
		// not the parent dir. In multiple forms.
		if delP == u.KlientParentDirectory || filepath.Clean(delP) == filepath.Clean(u.KlientParentDirectory) {
			break
		}

		// If there is any error, just bail out of the loop since we can't delete P's
		// parent if we were unable to delete P to begin with.
		if err := os.Remove(delP); err != nil {
			break
		}
	}

	// Remove the klientctl binary itself.
	// (The current binary is removing itself.. So emo...)
	if u.KlientctlPath != "" {
		if err := os.Remove(u.KlientctlPath); err != nil {
			warnings = append(warnings, fmt.Sprintf(
				"Warning: Failed to remove %s binary. This is not a critical issue.\n",
				u.KlientctlName,
			))
		}
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
	}

	return uninstaller.Uninstall()
}
