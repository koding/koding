package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/codegangsta/cli"
	"github.com/koding/klientctl/logging"
)

// UpdateCommand updates this binary if there's an update available.
func UpdateCommand(c *cli.Context) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "update")
		return 1
	}

	// Create and open the log file, to be safe in case it's missing.
	f, err := createLogFile(LogFilePath)
	if err != nil {
		fmt.Println(`Error: Unable to open log files.`)
	} else {
		log.SetHandler(logging.NewWriterHandler(f))
		log.Infof("Update created log file at %q", LogFilePath)
	}

	checkUpdate := NewCheckUpdate()

	// by pass random checking to force checking for update
	checkUpdate.ForceCheck = true

	yesUpdate, err := checkUpdate.IsUpdateAvailable()
	if err != nil {
		log.Errorf("Error checking if update is available. err:%s", err)
		fmt.Println(FailedCheckingUpdateAvailable)
		return 1
	}

	if !yesUpdate {
		fmt.Println("No update available.")
		return 0
	}

	s, err := newService()
	if err != nil {
		log.Errorf("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalError)
		return 1
	}

	fmt.Printf("An update is available...\n")
	fmt.Printf("Stopping %s...\n", KlientName)

	// stop klient before we update it
	if err := s.Stop(); err != nil {
		log.Errorf("Error stopping Service. err:%s", err)
		fmt.Println(FailedStopKlient)
		return 1
	}

	// download klient and kd to approprite place
	dlPaths := map[string]string{
		// /opt/kite/klient/klient
		filepath.Join(KlientDirectory, "klient"): S3KlientPath,

		// /usr/local/bin/kd
		filepath.Join(KlientctlDirectory, "kd"): S3KlientctlPath,
	}

	fmt.Println("Updating...")

	for localPath, remotePath := range dlPaths {
		if err := downloadRemoteToLocal(remotePath, localPath); err != nil {
			log.Errorf("Error updating. err:%s", err)
			fmt.Println(FailedDownloadUpdate)
			return 1
		}
	}

	// start klient now that it's done updating
	if err := s.Start(); err != nil {
		log.Errorf("Error starting Service. err:%s", err)
		fmt.Println(FailedStartKlient)
		return 1
	}

	var user string
	for _, s := range os.Environ() {
		env := strings.Split(s, "=")

		if len(env) != 2 {
			continue
		}

		if env[0] == "SUDO_USER" {
			user = env[1]
			break
		}
	}

	klientSh := klientSh{
		User:          user,
		KiteHome:      KiteHome,
		KlientBinPath: filepath.Join(KlientDirectory, "klient"),
		KontrolURL:    KontrolURL,
	}

	if err := klientSh.Create(filepath.Join(KlientDirectory, "klient.sh")); err != nil {
		log.Errorf("Error writing klient.sh file. err:%s", err)
		fmt.Println(FailedInstallingKlient)
		return 1
	}

	fmt.Printf("Successfully updated to latest version of %s.\n", Name)
	return 0
}

func downloadRemoteToLocal(remotePath, destPath string) error {
	// create the destination dir, if needed.
	if err := os.MkdirAll(filepath.Dir(destPath), 0755); err != nil {
		return err
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

	return binFile.Close()
}
