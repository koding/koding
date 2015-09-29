package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"runtime"

	"github.com/mitchellh/cli"
)

var (
	osName              = runtime.GOOS
	klientRemotePath    = fmt.Sprintf("https://koding-kd.s3.amazonaws.com/klient-%s", osName)
	klientctlRemotePath = fmt.Sprintf("https://koding-kd.s3.amazonaws.com/klientctl-%s", osName)
)

func UpdateCommandFactory() (cli.Command, error) {
	return &UpdateCommand{}, nil
}

type UpdateCommand struct{}

func (u *UpdateCommand) Run(_ []string) int {
	s, err := newService()
	if err != nil {
		log.Fatal(err)
	}

	// stop klient before we update it
	if err := s.Stop(); err != nil {
		log.Fatal(err)
	}

	// download klient to /opt/kite/klient
	klientBinPath, err := filepath.Abs(filepath.Join(KlientDirectory, "klient"))
	if err != nil {
		log.Fatal(err)
	}

	if err := downloadRemoteToLocal(klientRemotePath, klientBinPath); err != nil {
		log.Fatal(err)
	}

	// download klientctl to /usr/local/bin/kd
	klientctlBinPath, err := filepath.Abs(filepath.Join(KlientctlDirectory, "kd"))
	if err != nil {
		log.Fatal(err)
	}

	if err := downloadRemoteToLocal(klientctlRemotePath, klientctlBinPath); err != nil {
		log.Fatal(err)
	}

	// start klient now that it's done updating
	if err := s.Start(); err != nil {
		log.Fatal(err)
	}

	fmt.Println("Updated to latest version of kd.")

	return 0
}

func (u *UpdateCommand) Help() string {
	helpText := `
Usage: sudo %s update

		Update to latest version. sudo is required.
`
	return fmt.Sprintf(helpText, Name)
}

func (u *UpdateCommand) Synopsis() string {
	return "Update to latest version. sudo required."
}

func downloadRemoteToLocal(remoteFilePath, localFilePath string) error {
	binFile, err := os.OpenFile(localFilePath, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0755)
	if err != nil {
		if binFile != nil {
			binFile.Close()
		}

		return nil
	}

	res, err := http.Get(remoteFilePath)
	if err != nil {
		return err
	}

	if res.Body != nil {
		defer res.Body.Close()
	}

	if _, err := io.Copy(binFile, res.Body); err != nil {
		return err
	}

	return binFile.Close()
}
