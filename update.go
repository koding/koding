package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/mitchellh/cli"
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

	fmt.Printf("Stopped klient")

	// download klient and kd to approprite place
	dlPaths := map[string]string{
		// /opt/kite/klient/klient
		filepath.Join(KlientDirectory, "klient"): S3KlientPath,

		// /usr/local/bin/kd
		filepath.Join(KlientctlDirectory, "kd"): S3KlientctlPath,
	}

	for localPath, remotePath := range dlPaths {
		if err := downloadRemoteToLocal(remotePath, localPath); err != nil {
			log.Fatal(err)
		}
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

func downloadRemoteToLocal(remotePath, destPath string) error {
	// create the destination dir, if needed.
	if err := os.MkdirAll(filepath.Base(destPath), 0755); err != nil {
		log.Fatal(err)
	}

	// open file in specified path to write to
	perms := os.O_WRONLY | os.O_CREATE | os.O_TRUNC
	binFile, err := os.OpenFile(destPath, perms, 0755)
	if err != nil {
		if binFile != nil {
			binFile.Close()
		}

		return nil
	}

	// get from remote
	res, err := http.Get(remotePath)
	if err != nil {
		return err
	}
	defer res.Body.Close()

	// copy remote file to destination path
	if _, err := io.Copy(binFile, res.Body); err != nil {
		return err
	}

	fmt.Printf("Downloaded %s to %s\n", remotePath, destPath)

	return binFile.Close()
}
