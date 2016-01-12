package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/codegangsta/cli"
	"github.com/koding/klientctl/logging"
	"github.com/leeola/service"
)

// newService provides a preconfigured (based on klientctl's config)
// service object to install, uninstall, start and stop Klient.
func newService() (service.Service, error) {
	// TODO: Add hosts's username
	svcConfig := &service.Config{
		Name:        "klient",
		DisplayName: "klient",
		Description: "Koding Service Connector",
		Executable:  filepath.Join(KlientDirectory, "klient.sh"),
		Option: map[string]interface{}{
			"LogStderr": true,
			"LogStdout": true,
		},
	}

	return service.New(&serviceProgram{}, svcConfig)
}

type serviceProgram struct{}

func (p *serviceProgram) Start(s service.Service) error {
	fmt.Println("Error: serviceProgram Start called")
	return nil
}

func (p *serviceProgram) Stop(s service.Service) error {
	fmt.Println("Error: serviceProgram Stop called")
	return nil
}

// InstallCommandFactory is the factory method for InstallCommand.
func InstallCommandFactory(c *cli.Context) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "install")
		return 1
	}

	// Now that we created the logfile, set our logger handler to use that newly created
	// file, so that we can log errors during installation.
	f, err := createLogFile(LogFilePath)
	if err != nil {
		fmt.Println(`Error: Unable to open log files.`)
	} else {
		log.SetHandler(logging.NewWriterHandler(f))
		log.Infof("Installation created log file")
	}

	authToken := c.Args().Get(0)

	// We need to check if the authToken is somehow empty, because klient
	// will default to user/pass if there is no auth token (despite setting
	// the token flag)
	if strings.TrimSpace(authToken) == "" {
		cli.ShowCommandHelp(c, "install")
		return 1
	}

	// Get the supplied kontrolURL, defaulting to the prod kontrol if
	// empty.
	kontrolURL := strings.TrimSpace(c.String("kontrol"))
	if kontrolURL == "" {
		// Default to the config's url
		kontrolURL = KontrolURL
	}

	klientShPath, err := filepath.Abs(filepath.Join(KlientDirectory, "klient.sh"))
	if err != nil {
		log.Errorf("Error creating klient.sh path: %s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	klientBinPath, err := filepath.Abs(filepath.Join(KlientDirectory, "klient"))
	if err != nil {
		log.Errorf(
			"Error creating klient binary path. path:%s, err:%s",
			filepath.Join(KlientDirectory, "klient"), err,
		)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	// Create the installation dir, if needed.
	err = os.MkdirAll(KlientDirectory, 0755)
	if err != nil {
		log.Errorf(
			"Error creating klient binary directory(s). path:%s, err:%s",
			KlientDirectory, err,
		)
		fmt.Println(FailedInstallingKlient)
		return 1
	}

	// TODO: Accept `kd install --user foo` flag to replace the
	// environ checking.
	var sudoCmd string
	for _, s := range os.Environ() {
		env := strings.Split(s, "=")

		if len(env) != 2 {
			continue
		}

		if env[0] == "SUDO_USER" {
			sudoCmd = fmt.Sprintf("sudo -u %s ", env[1])
			break
		}
	}

	// TODO: Stop using this klient.sh file.
	// If the klient.sh file is missing, write it. We can use build tags
	// for os specific tags, if needed.
	_, err = os.Stat(klientShPath)
	if err != nil {
		if os.IsNotExist(err) {
			klientShFile := []byte(fmt.Sprintf(`#!/bin/sh
%sKITE_HOME=%s %s --kontrol-url=%s
`,
				sudoCmd, KiteHome, klientBinPath, kontrolURL))

			// perm -rwr-xr-x, same as klient
			if err := ioutil.WriteFile(klientShPath, klientShFile, 0755); err != nil {
				log.Errorf("Error writing klient.sh file. err:%s", err)
				fmt.Println(FailedInstallingKlient)
				return 1
			}

			fmt.Printf("Created %s\n", klientShPath)

		} else {
			// Unknown error stating (possibly permission), exit
			// TODO: Print UX friendly err
			fmt.Println("Error:", err)
			return 1
		}
	}

	fmt.Println("Downloading...")

	if err = downloadRemoteToLocal(S3KlientPath, klientBinPath); err != nil {
		log.Errorf("Error downloading klient binary. err:%s", err)
		fmt.Printf(FailedDownloadingKlient)
		return 1
	}

	fmt.Printf("Created %s\n", klientBinPath)
	fmt.Printf(`Authenticating you to the %s

`, KlientName)

	cmd := exec.Command(klientBinPath, "-register",
		"-token", authToken,
		"--kontrol-url", kontrolURL,
		"--kite-home", KiteHome,
	)
	// Note that we are *only* printing to Stdout. This is done because
	// Klient logs error messages to Stderr, and we want to control the UX for
	// that interaction.
	//
	// TODO: Logg Klient's Stderr message on error, if any.
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		log.Errorf("Error registering klient. err:%s", err)
		fmt.Println(FailedRegisteringKlient)
		return 1
	}

	fmt.Printf("Created %s\n", filepath.Join(KiteHome, "kite.key"))

	// Klient is setting the wrong file permissions when installed by ctl,
	// so since this is just ctl problem, we'll just fix the permission
	// here for now.
	if err = os.Chmod(KiteHome, 0755); err != nil {
		log.Errorf(
			"Error chmodding KiteHome directory. dir:%s, err:%s",
			KiteHome, err,
		)
		fmt.Println(FailedInstallingKlient)
		return 1
	}

	if err = os.Chmod(filepath.Join(KiteHome, "kite.key"), 0644); err != nil {
		log.Errorf(
			"Error chmodding kite.key. path:%s, err:%s",
			filepath.Join(KiteHome, "kite.key"), err,
		)
		fmt.Println(FailedInstallingKlient)
		return 1
	}

	// Create our interface to the OS specific service
	s, err := newService()
	if err != nil {
		log.Errorf("Error creating Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	// Install the klient binary as a OS service
	if err = s.Install(); err != nil {
		log.Errorf("Error installing Service. err:%s", err)
		fmt.Println(GenericInternalNewCodeError)
		return 1
	}

	// Tell the service to start. Normally it starts automatically, but
	// if the user told the service to stop (previously), it may not
	// start automatically.
	//
	// Note that the service may error if it is already running, so
	// we're ignoring any starting errors here. We will verify the
	// connection below, anyway.
	s.Start()

	fmt.Println("Verifying installation...")
	err = WaitUntilStarted(KlientAddress, 5, 1*time.Second)

	// After X times, if err != nil we failed to connect to klient.
	// Inform the user.
	if err != nil {
		log.Errorf("Error verifying the installation of klient. %s", err)
		fmt.Println(FailedInstallingKlient)
		return 1
	}

	fmt.Printf("\n\nSuccessfully installed and started the %s!\n", KlientName)

	return 0
}

// createLogFile opens the given path for writing, sets the permissions,
// and returns it. Creating it if needed. The caller is responsible for closing the
// file when no longer needed.
func createLogFile(p string) (*os.File, error) {
	f, err := os.OpenFile(p, os.O_WRONLY|os.O_APPEND|os.O_CREATE, 0666)
	if err != nil {
		return nil, err
	}

	if err := f.Chmod(0666); err != nil {
		// Close the file, since it opened properly but we failed to Chmod it.
		f.Close()
		return nil, err
	}

	return f, nil
}
