package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/kardianos/service"
	"github.com/koding/kite"
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

func InstallCommandFactory(k *kite.Client) cli.CommandFactory {
	return func() (cli.Command, error) {
		return &InstallCommand{
			k: k,
		}, nil
	}
}

type InstallCommand struct {
	k *kite.Client
}

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
KITE_HOME=%s %s
`,
				KiteHome, klientBinPath))

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

	// TODO: Register with kontrol here

	s, err := newService()
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	err = s.Install()
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	fmt.Println("Success")
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
