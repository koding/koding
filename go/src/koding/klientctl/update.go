package main

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"koding/klientctl/config"
	"net/http"
	"net/url"
	"os"
	"os/user"
	"path/filepath"
	"runtime"
	"strconv"

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

	var (
		forceUpdate   = c.Bool("force")
		klientVersion = c.Int("klient-version")
		klientChannel = c.String("klient-channel")
		kdVersion     = c.Int("kd-version")
		kdChannel     = c.String("kd-channel")
	)

	if kdChannel == "" {
		kdChannel = config.Environment
	}

	if klientChannel == "" {
		klientChannel = config.Environment
	}

	// Create and open the log file, to be safe in case it's missing.
	f, err := createLogFile(LogFilePath)
	if err != nil {
		fmt.Println(`Error: Unable to open log files.`)
	} else {
		log.SetHandler(logging.NewWriterHandler(f))
		log.Info("Update created log file at %q", LogFilePath)
	}

	if !shouldTryUpdate(kdVersion, klientVersion, forceUpdate) {
		yesUpdate, err := checkUpdate()
		if err != nil {
			log.Error("Error checking if update is available. err:%s", err)
			fmt.Println(FailedCheckingUpdateAvailable)
			return 1
		}

		if !yesUpdate {
			fmt.Println("No update available.")
			return 0
		} else {
			fmt.Println("An update is available.")
		}
	}

	kontrolURL := config.KontrolURL
	if c, err := kiteconfig.NewFromKiteKey(config.KiteKeyPath); err == nil && c.KontrolURL != "" {
		// BUG(rjeczalik): sandbox returns a kite.key on -register method that has
		// KontrolURL set to default value. We workaround it here by ignoring the
		// value.
		if u, err := url.Parse(c.KontrolURL); err == nil && u.Host != "127.0.0.1:3000" {
			kontrolURL = c.KontrolURL
		}
	}

	klientSh := klientSh{
		User:          sudoUserFromEnviron(os.Environ()),
		KiteHome:      config.KiteHome,
		KlientBinPath: filepath.Join(KlientDirectory, "klient"),
		KontrolURL:    kontrolURL,
	}

	// ensure the klient home dir is writeable by user
	if klientSh.User != "" {
		ensureWriteable(KlientctlDirectory, klientSh.User)
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

	fmt.Printf("Stopping %s...\n", config.KlientName)

	// stop klient before we update it
	if err := s.Stop(); err != nil {
		log.Error("Error stopping Service. err:%s", err)
		fmt.Println(FailedStopKlient)
		return 1
	}

	if kdVersion == 0 {
		var err error

		kdVersion, err = latestVersion(config.S3KlientctlLatest)
		if err != nil {
			log.Error("Error checking if update is available. err: %s", err)
			fmt.Println(FailedCheckingUpdateAvailable)
			return 1
		}
	}

	if klientVersion == 0 {
		var err error

		klientVersion, err = latestVersion(config.S3KlientLatest)
		if err != nil {
			log.Error("Error checking if update is available. err: %s", err)
			fmt.Println(FailedCheckingUpdateAvailable)
			return 1
		}
	}

	// download klient and kd to approprite place
	dlPaths := map[string]string{
		// /opt/kite/klient/klient
		filepath.Join(KlientDirectory, "klient"): config.S3Klient(klientVersion, klientChannel),

		// /usr/local/bin/kd
		filepath.Join(KlientctlDirectory, "kd"): config.S3Klientctl(kdVersion, kdChannel),
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

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("%s: %s", remotePath, http.StatusText(res.StatusCode))
	}

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

func ensureWriteable(dir, username string) error {
	u, err := user.Lookup(username)
	if err != nil {
		return err
	}

	uid, err := strconv.Atoi(u.Uid)
	if err != nil {
		return err
	}

	gid, err := strconv.Atoi(u.Gid)
	if err != nil {
		return err
	}

	return os.Chown(dir, uid, gid)
}

func shouldTryUpdate(kdVersion, klientVersion int, forceUpdate bool) bool {
	if forceUpdate {
		return true
	}

	if kdVersion == 0 && klientVersion == 0 {
		return true
	}

	return false
}

func checkUpdate() (bool, error) {
	checkUpdate := NewCheckUpdate()

	// by pass random checking to force checking for update
	checkUpdate.ForceCheck = true

	return checkUpdate.IsUpdateAvailable()
}
