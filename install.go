package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/kardianos/service"
	"github.com/mitchellh/cli"
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
	}

	return service.New(&serviceProgram{}, svcConfig)
}

type serviceProgram struct{}

func (p *serviceProgram) Start(s service.Service) error {
	fmt.Println("serviceProgram Start called o_O")
	return nil
}

func (p *serviceProgram) Stop(s service.Service) error {
	fmt.Println("serviceProgram Stop called o_O")
	return nil
}

func InstallCommandFactory() (cli.Command, error) {
	return &InstallCommand{}, nil
}

type InstallCommand struct{}

func (c *InstallCommand) Run(_ []string) int {
	klientShPath, err := filepath.Abs(filepath.Join(KlientDirectory, "klient.sh"))
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	klientBinPath, err := filepath.Abs(filepath.Join(KlientDirectory, "klient"))
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	// TODO: Stop using this klient.sh file.
	// If the klient.sh file is missing, write it. We can use build tags
	// for os specific tags, if needed.
	_, err = os.Stat(klientShPath)
	if err != nil {
		if os.IsNotExist(err) {
			klientShFile := []byte(fmt.Sprintf(`#!/bin/sh
KITE_HOME=%s %s --kontrol-url=%s
`,
				KiteHome, klientBinPath, KontrolUrl))

			// perm -rwr-xr-x, same as klient
			err := ioutil.WriteFile(klientShPath, klientShFile, 0755)
			if err != nil {
				// TODO: Print UX friendly err
				fmt.Println("Error:", err)
				return 1
			}

		} else {
			// Unknown error stating (possibly permission), exit
			// TODO: Print UX friendly err
			fmt.Println("Error:", err)
			return 1
		}
	}

	// TODO: Download klient and write it to the KlientDirectory, here.
	// For now, we're just requiring that it's already downloaded locally.
	_, err = os.Stat(klientBinPath)
	if err != nil && os.IsNotExist(err) {
		fmt.Println("In this alpha version of kd, you must download klient locally first")
		return 1
	}

	fmt.Printf(`Authenticating you to the %s
Please provide your Koding Username and Password when prompted..

`, KlientName)

	cmd := exec.Command(klientBinPath, "-register",
		"--kontrol-url", KontrolUrl, "--kite-home", KiteHome)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	err = cmd.Run()
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	// Klient is setting the wrong file permissions when installed by ctl,
	// so since this is just ctl problem, we'll just fix the permission
	// here for now.
	err = os.Chmod(KiteHome, 0755)
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}
	err = os.Chmod(filepath.Join(KiteHome, "kite.key"), 0644)
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	// Create our interface to the OS specific service
	s, err := newService()
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	// Install the klient binary as a OS service
	err = s.Install()
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
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

	// Create a kite to talk to klient, so we can verify that it installed
	// properly before telling the user success
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	fmt.Println("Verifying installation...")

	// Try multiple times to connect to Klient, and return the final error
	// if needed.
	for i := 0; i < 5; i++ {
		time.Sleep(1 * time.Second)
		err = k.Dial()

		if err == nil {
			break
		}
	}

	// After X times, if err != nil we failed to connect to klient.
	// Inform the user.
	if err != nil {
		fmt.Printf(`Error: Failed to verify the installation of the %s.

Reason: %s
`,
			KlientName, err.Error())
		return 1
	}

	fmt.Printf("\n\nSuccessfully installed the %s!\n", KlientName)
	return 0
}

func (*InstallCommand) Help() string {
	helpText := `
Usage: %s stop

	Install the %s.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*InstallCommand) Synopsis() string {
	return fmt.Sprintf("Install the %s", KlientName)
}
