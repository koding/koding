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

func InstallCommand(c *cli.Context) int {
	if len(c.Args()) < 1 {
		cli.ShowCommandHelp(c, "install")
		return 1
	}

	authToken := c.Args().Get(0)

	// We need to check if the authToken is somehow empty, because klient
	// will default to user/pass if there is no auth token (despite setting
	// the token flag)
	if authToken == "" {
		cli.ShowCommandHelp(c, "install")
		return 1
	}

	klientShPath, err := filepath.Abs(filepath.Join(KlientDirectory, "klient.sh"))
	if err != nil {
		fmt.Printf("Error getting %s wrapper path: '%s'\n", KlientName, err)
		return 1
	}

	klientBinPath, err := filepath.Abs(filepath.Join(KlientDirectory, "klient"))
	if err != nil {
		fmt.Printf("Error getting %s path: '%s'\n", KlientName, err)
		return 1
	}

	// Create the installation dir, if needed.
	err = os.MkdirAll(KlientDirectory, 0755)
	if err != nil {
		fmt.Printf("Error creating directory to hold: '%s'\n", KlientName, err)
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
%sKITE_HOME=%s %s --kontrol-url=%s -debug
`,
				sudoCmd, KiteHome, klientBinPath, KontrolUrl))

			// perm -rwr-xr-x, same as klient
			err := ioutil.WriteFile(klientShPath, klientShFile, 0755)
			if err != nil {
				fmt.Printf("Error creating %s wrapper: '%s'\n", KlientName, err)
				return 1
			}

		} else {
			// Unknown error stating (possibly permission), exit
			// TODO: Print UX friendly err
			fmt.Println("Error:", err)
			return 1
		}
	}

	fmt.Println("Downloading...")

	if err = downloadRemoteToLocal(S3KlientPath, klientBinPath); err != nil {
		fmt.Printf("Error downloading %s: '%s'\n", KlientName, err)
		return 1
	}

	fmt.Printf(`Authenticating you to the %s

`, KlientName)

	cmd := exec.Command(klientBinPath, "-register",
		"-token", authToken,
		"--kontrol-url", KontrolUrl, "--kite-home", KiteHome)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	err = cmd.Run()
	if err != nil {
		fmt.Printf("Error registering %s: '%s'\n", KlientName, err)
		return 1
	}

	// Klient is setting the wrong file permissions when installed by ctl,
	// so since this is just ctl problem, we'll just fix the permission
	// here for now.
	if err = os.Chmod(KiteHome, 0755); err != nil {
		fmt.Printf("Error installing %s: '%s'\n", KlientName, err)
		return 1
	}

	if err = os.Chmod(filepath.Join(KiteHome, "kite.key"), 0644); err != nil {
		fmt.Printf("Error installing kite.key: '%s'\n", err)
		return 1
	}

	// Create our interface to the OS specific service
	s, err := newService()
	if err != nil {
		fmt.Printf("Error starting service: '%s'\n", err)
		return 1
	}

	// Install the klient binary as a OS service
	if err = s.Install(); err != nil {
		fmt.Printf("Error installing service: '%s'\n", err)
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
		fmt.Printf("Error verifying the installation of %s: '%s'\n", KlientName, err)
		return 1
	}

	fmt.Printf("\n\nSuccessfully installed and started the %s!\n", KlientName)

	return 0
}
