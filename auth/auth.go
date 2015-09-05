package auth

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
)

//go:generate go-bindata -pkg auth save-kite-key.sh

// SaveKiteKey is a temporary method which runs the bundled `save-kite-key.sh`
// script to get credentials for the given VM.
func SaveKiteKey(user, host string) error {
	installBytes, err := Asset("save-kite-key.sh")
	if err != nil {
		return err
	}

	cmdProc := exec.Command("sh")

	cmdProc.Env = append(os.Environ(), []string{
		fmt.Sprintf("SSHUSER=%s", user),
		fmt.Sprintf("SSHHOST=%s", host),
	}...)

	cmdProc.Stdout = os.Stdout
	cmdProc.Stderr = os.Stderr

	// Because we want to pipe the script in, we need to convert the bytes
	// into a Reader
	cmdProc.Stdin = bytes.NewReader(installBytes)

	return cmdProc.Run()
}
