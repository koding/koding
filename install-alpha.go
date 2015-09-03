package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
)

//go:generate go-bindata install-alpha.sh

// runInstallAlpha is a temporary prototype file which will run the
// bundled install-alpha.sh file, to get credentials for the given
// vm host.
func runInstallAlpha(user, host string) error {
	installBytes, err := Asset("install-alpha.sh")
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
