package main

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"koding/klientctl/config"
	"net/http"
	"os"
	"path/filepath"
	"runtime"

	"github.com/codegangsta/cli"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/service"
)

// UpdateCommand updates this binary if there's an update available.
func UpdateCommand(c *cli.Context, log logging.Logger, _ string) int {
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
		log.Info("Update created log file at %q", LogFilePath)
	}

	checkUpdate := NewCheckUpdate()

	// by pass random checking to force checking for update
	checkUpdate.ForceCheck = true

	yesUpdate, err := checkUpdate.IsUpdateAvailable()
	if err != nil {
		log.Error("Error checking if update is available. err:%s", err)
		fmt.Println(FailedCheckingUpdateAvailable)
		return 1
	}

	if !yesUpdate {
		fmt.Println("No update available.")
		return 0
	}

	kontrolURL := config.KontrolURL
	if c, err := kiteconfig.NewFromKiteKey(config.KiteKeyPath); err == nil && c.KontrolURL != "" {
		kontrolURL = c.KontrolURL
	}

	klientSh := klientSh{
		User:          sudoUserFromEnviron(os.Environ()),
		KiteHome:      config.KiteHome,
		KlientBinPath: filepath.Join(KlientDirectory, "klient"),
		KontrolURL:    kontrolURL,
	}

	opts := &ServiceOptions{
		Username:   klientSh.User,
		KontrolURL: klientSh.KontrolURL,
	}

	s, err := newService(opts)
	if err != nil {
		log.Error("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	fmt.Printf("An update is available...\n")
	fmt.Printf("Stopping %s...\n", config.KlientName)

	// stop klient before we update it
	if err := s.Stop(); err != nil {
		log.Error("Error stopping Service. err:%s", err)
		fmt.Println(FailedStopKlient)
		return 1
	}

	klientVersion, err := latestVersion(config.S3KlientLatest)
	if err != nil {
		log.Error("Error checking if update is available. err: %s", err)
		fmt.Println(FailedCheckingUpdateAvailable)
		return 1
	}

	klientctlVersion, err := latestVersion(config.S3KlientctlLatest)
	if err != nil {
		log.Error("Error checking if update is available. err: %s", err)
		fmt.Println(FailedCheckingUpdateAvailable)
		return 1
	}

	// download klient and kd to approprite place
	dlPaths := map[string]string{
		// /opt/kite/klient/klient
		filepath.Join(KlientDirectory, "klient"): config.S3Klient(klientVersion),

		// /usr/local/bin/kd
		filepath.Join(KlientctlDirectory, "kd"): config.S3Klientctl(klientctlVersion),
	}

	fmt.Println("Updating...")

	for localPath, remotePath := range dlPaths {
		if err := downloadRemoteToLocal(remotePath, localPath); err != nil {
			log.Error("Error updating. err:%s", err)
			fmt.Println(FailedDownloadUpdate)
			return 1
		}
	}

	klientScript := filepath.Join(KlientDirectory, "klient.sh")

	if err := klientSh.Create(klientScript); err != nil {
		log.Error("Error writing klient.sh file. err:%s", err)
		fmt.Println(FailedInstallingKlient)
		return 1
	}

	// try to migrate from old managed klient to new kd-installed klient
	switch runtime.GOOS {
	case "darwin":
		oldS, err := service.New(&serviceProgram{}, &service.Config{
			Name:       "com.koding.klient",
			Executable: klientScript,
		})

		if err != nil {
			break
		}

		oldS.Stop()
		oldS.Uninstall()
	}

	// try to uninstall first, otherwise Install may fail if
	// klient.plist or klient init script already exist
	s.Uninstall()

	// Install the klient binary as a OS service
	if err = s.Install(); err != nil {
		log.Error("Error installing Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	// start klient now that it's done updating
	if err := s.Start(); err != nil {
		log.Error("Error starting Service. err:%s", err)
		fmt.Println(FailedStartKlient)
		return 1
	}

	fmt.Printf("Successfully updated to latest version of %s.\n", config.Name)
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

	var buf bytes.Buffer // to restore begining of a response body consumed by gzip.NewReader
	var body io.Reader = io.MultiReader(&buf, res.Body)

	// If body contains gzip header, it means the payload was compressed.
	// Relying solely on Content-Type == "application/gzip" check
	// was not reliable.
	if r, err := gzip.NewReader(io.TeeReader(res.Body, &buf)); err == nil {
		if r, err = gzip.NewReader(body); err == nil {
			body = r
		}
	}

	// copy remote file to destination path
	if _, err := io.Copy(binFile, body); err != nil {
		return err
	}

	return binFile.Close()
}
