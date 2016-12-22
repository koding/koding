package main

import (
	"bytes"
	"errors"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	konfig "koding/kites/config"
	"koding/kites/config/configstore"
	"koding/klient/uploader"
	"koding/klientctl/config"
	"koding/klientctl/metrics"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
	"github.com/koding/service"
)

type ServiceOptions struct {
	Username string
}

var defaultServiceOpts = &ServiceOptions{
	Username: konfig.CurrentUser.Username,
}

var klientShTmpl = template.Must(template.New("").Parse(`#!/bin/bash

# Koding Service Connector
# Copyright (C) 2012-2016 Koding Inc., all rights reserved.

# source environment
for src in /etc/{environment,profile,bashrc}; do
	[[ -f ${src} ]] && source ${src}
done

isOSX=$(uname -v | grep -Ec '^Darwin Kernel.*')

if [[ ${isOSX} -ne 0 ]]; then
	# wait under OS-X till network is ready
	. /etc/rc.common

	CheckForNetwork

	while [ "${NETWORKUP}" != "-YES-" ]; do
		sleep 5
		NETWORKUP=
		CheckForNetwork
	done
fi

# configure environment

ulimit -n 5000

# start klient

export USERNAME=${USERNAME:-{{.User}}}
{{if .KlientBinPath}}
export KLIENT_BIN=${KLIENT_BIN:-{{.KlientBinPath}}}
{{else}}
export KLIENT_BIN=${KLIENT_BIN:-/opt/kite/klient/klient}
{{end}}
export HOME=$(eval cd ~${USERNAME}; pwd)
export PATH=$PATH:/usr/local/bin

sudo -E -u "${USERNAME}" ${KLIENT_BIN}
`))

// newService provides a preconfigured (based on klientctl's config)
// service object to install, uninstall, start and stop Klient.
func newService(opts *ServiceOptions) (service.Service, error) {
	if opts == nil {
		opts = defaultServiceOpts
	}

	// TODO: Add hosts's username
	svcConfig := &service.Config{
		Name:        "klient",
		DisplayName: "klient",
		Description: "Koding Service Connector",
		Executable:  filepath.Join(KlientDirectory, "klient.sh"),
		Option: map[string]interface{}{
			"LogStderr":     true,
			"LogStdout":     true,
			"After":         "network.target",
			"RequiredStart": "$network",
			"LogFile":       true,
			"Environment": map[string]string{
				"USERNAME": opts.Username,
			},
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

func latestVersion(url string) (int, error) {
	resp, err := http.Get(url)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()

	p, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return 0, err
	}

	version, err := strconv.ParseUint(string(bytes.TrimSpace(p)), 10, 32)
	if err != nil {
		return 0, err
	}

	return int(version), nil
}

// The implementation of InstallCommandFactory, with an error return. This
// allows us to track the error metrics.
func InstallCommandFactory(c *cli.Context, log logging.Logger, _ string) (exit int, err error) {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "install")
		return 1, errors.New("incorrect cli usage: no args")
	}

	// Now that we created the logfile, set our logger handler to use that newly created
	// file, so that we can log errors during installation.
	f, err := createLogFile(LogFilePath)
	if err != nil {
		fmt.Println(`Error: Unable to open log files.`)
	} else {
		log.SetHandler(logging.NewWriterHandler(f))
		log.Info("Installation created log file at %q", LogFilePath)
	}

	// Track all failed installations.
	defer func() {
		if err != nil {
			log.Error(err.Error())
			metrics.TrackInstallFailed(err.Error(), config.VersionNum())
		}
	}()

	authToken := c.Args().Get(0)

	// We need to check if the authToken is somehow empty, because klient
	// will default to user/pass if there is no auth token (despite setting
	// the token flag)
	if strings.TrimSpace(authToken) == "" {
		cli.ShowCommandHelp(c, "install")
		return 1, errors.New("incorrect cli usage: missing token")
	}

	// Create the installation dir, if needed.
	if err := os.MkdirAll(KlientDirectory, 0755); err != nil {
		log.Error(
			"Error creating klient binary directory(s). path:%s, err:%s",
			KlientDirectory, err,
		)
		fmt.Println(FailedInstallingKlient)
		return 1, fmt.Errorf("failed creating klient binary: %s", err)
	}

	klientBinPath := filepath.Join(KlientDirectory, "klient")

	// TODO: Accept `kd install --user foo` flag to replace the
	// environ checking.
	klientSh := klientSh{
		User:          konfig.CurrentUser.Username,
		KlientBinPath: klientBinPath,
	}

	if err := klientSh.Create(filepath.Join(KlientDirectory, "klient.sh")); err != nil {
		err = fmt.Errorf("error writing klient.sh file: %s", err)
		fmt.Println(FailedInstallingKlient)
		return 1, err
	}

	fmt.Println("Downloading...")

	version, err := latestVersion(config.Konfig.Endpoints.KlientLatest.Public.String())
	if err != nil {
		fmt.Printf(FailedDownloadingKlient)
		return 1, fmt.Errorf("error getting latest klient version: %s", err)
	}

	if err := downloadRemoteToLocal(config.S3Klient(version, config.Environment), klientBinPath); err != nil {
		fmt.Printf(FailedDownloadingKlient)
		return 1, fmt.Errorf("error downloading klient binary: %s", err)
	}

	fmt.Printf("Created %s\n", klientBinPath)
	fmt.Printf(`Authenticating you to the %s

`, config.KlientName)

	cmd := exec.Command(klientBinPath, "-register",
		"-token", authToken,
		"--kontrol-url", strings.TrimSpace(c.String("kontrol")),
	)

	var errBuf bytes.Buffer

	// Note that we are *only* printing to Stdout. This is done because
	// Klient logs error messages to Stderr, and we want to control the UX for
	// that interaction.
	//
	// TODO: Logg Klient's Stderr message on error, if any.
	cmd.Stdout = os.Stdout
	cmd.Stdin = os.Stdin
	cmd.Stderr = &errBuf

	if err := cmd.Run(); err != nil {
		err = fmt.Errorf("error registering klient: %s, klient stderr: %s", err, errBuf.String())
		fmt.Println(FailedRegisteringKlient)
		return 1, err
	}

	// Best-effort attempts at fixinig permissions and ownership, ignore any errors.
	_ = configstore.FixOwner()

	opts := &ServiceOptions{
		Username: klientSh.User,
	}

	// Create our interface to the OS specific service
	s, err := newService(opts)
	if err != nil {
		fmt.Println(GenericInternalNewCodeError)
		return 1, fmt.Errorf("error creating Service: %s", err)
	}

	// try to uninstall first, otherwise Install may fail if
	// klient.plist or klient init script already exist
	s.Uninstall()

	// Install the klient binary as a OS service
	if err := s.Install(); err != nil {
		fmt.Println(GenericInternalNewCodeError)
		return 1, fmt.Errorf("error installing Service: %s", err)
	}

	// Tell the service to start. Normally it starts automatically, but
	// if the user told the service to stop (previously), it may not
	// start automatically.
	//
	// Note that the service may error if it is already running, so
	// we're ignoring any starting errors here. We will verify the
	// connection below, anyway.
	if err := s.Start(); err != nil {
		fmt.Println(FailedStartKlient)
		return 1, fmt.Errorf("error starting klient service: %s", err)
	}

	fmt.Println("Verifying installation...")
	err = WaitUntilStarted(config.Konfig.Endpoints.Klient.Private.String(), CommandAttempts, CommandWaitTime)

	// After X times, if err != nil we failed to connect to klient.
	// Inform the user.
	if err != nil {
		fmt.Println(FailedInstallingKlient)
		return 1, fmt.Errorf("error verifying the installation of klient: %s", err)
	}

	// Best-effort attempts at fixinig permissions and ownership, ignore any errors.
	_ = uploader.FixPerms()

	// track metrics
	metrics.TrackInstall(config.VersionNum())

	fmt.Printf("\n\nSuccessfully installed and started the %s!\n", config.KlientName)

	return 0, nil
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

// klientSh implements methods for creating the klient.sh file.
type klientSh struct {
	// The username that the sudo command will run under.
	User string

	// The klient bin location, which will be the actual bin run from the klient.sh file
	KlientBinPath string
}

// Format returns the klient.sh struct formatted for the actual file.
func (k klientSh) Format() (string, error) {
	var buf bytes.Buffer

	if err := klientShTmpl.Execute(&buf, &k); err != nil {
		return "", nil
	}

	return buf.String(), nil
}

// Create writes the result of Format() to the given path.
func (k klientSh) Create(file string) error {
	p, err := k.Format()
	if err != nil {
		return err
	}

	// perm -rwr-xr-x, same as klient
	return ioutil.WriteFile(file, []byte(p), 0755)
}
