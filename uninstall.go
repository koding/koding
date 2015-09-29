package main

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/mitchellh/cli"
)

func UninstallCommandFactory() (cli.Command, error) {
	return &UninstallCommand{}, nil
}

type UninstallCommand struct{}

func (c *UninstallCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		fmt.Println("Error uninstalling %s: '%s'\n", KlientName, err)
		return 1
	}

	if err := s.Uninstall(); err != nil {
		fmt.Println("Error uninstalling %s: '%s'\n", KlientName, err)
		return 1
	}

	// For the ease of reinstallation, remove the user's kite key so that
	// they're not prompted to replace it next time they auth.
	err = os.Remove(filepath.Join(KiteHome, "kite.key"))
	// No need to exit with an error when removing the key, just log it.
	if err != nil {
		fmt.Printf("Warning: Failed to remove kite.key. This is not a critical issue.\n")
	}

	fmt.Printf("Successfully uninstalled %s\n", KlientName)
	return 0
}

func (*UninstallCommand) Help() string {
	helpText := `
Usage: %s list

	Uninstall the %s.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*UninstallCommand) Synopsis() string {
	return fmt.Sprintf("Uninstall the %s", KlientName)
}
