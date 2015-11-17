package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/codegangsta/cli"
)

// StopCommand removes local klient. Requires sudo.
//
// TODO: remove all artifacts, ie bolt db, ssh keys, kd etc.
func UninstallCommand(c *cli.Context) int {
	s, err := newService()
	if err != nil {
		fmt.Printf("Error uninstalling %s: '%s'\n", KlientName, err)
		return 1
	}

	if err := s.Uninstall(); err != nil {
		fmt.Printf("Error uninstalling %s: '%s'\n", KlientName, err)
		return 1
	}

	// For the ease of reinstallation, remove the user's kite key so that
	// they're not prompted to replace it next time they auth.
	err = os.Remove(filepath.Join(KiteHome, "kite.key"))
	// No need to exit with an error when removing the key, just log it.
	if err != nil {
		fmt.Printf("Warning: Failed to remove kite.key. This is not a critical issue.\n")
	}

	// Remove the Klient directory
	if err = os.RemoveAll(KlientDirectory); err != nil {
		fmt.Printf(
			"Warning: Failed to remove %s binary. This is not a critical issue.\n",
			KlientName,
		)
	}

	// Remove the kd binary
	if err := os.Remove(filepath.Join(KlientctlDirectory, KlientctlBinName)); err != nil {
		fmt.Printf(
			"Warning: Failed to remove %s binary. This is not a critical issue.\n",
			Name,
		)
	}

	fmt.Printf("Successfully uninstalled %s\n", KlientName)
	return 0
}
