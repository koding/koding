package daemon

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"path/filepath"
	"text/template"

	konfig "koding/kites/config"

	"github.com/koding/service"
)

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

type ServiceOptions struct {
	Username string
}

var defaultServiceOpts = &ServiceOptions{
	Username: konfig.CurrentUser.Username,
}

// newService provides a preconfigured (based on klientctl's config)
// service object to install, uninstall, start and stop Klient.
func (c *Client) newService(opts *ServiceOptions) (service.Service, error) {
	if opts == nil {
		opts = defaultServiceOpts
	}

	// TODO: Add hosts's username
	svcConfig := &service.Config{
		Name:        "klient",
		DisplayName: "klient",
		Description: "Koding Service Connector",
		Executable:  filepath.Join(c.details.KlientHome, "klient.sh"),
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

type serviceProgram struct{}

func (p *serviceProgram) Start(s service.Service) error {
	fmt.Println("Error: serviceProgram Start called")
	return nil
}

func (p *serviceProgram) Stop(s service.Service) error {
	fmt.Println("Error: serviceProgram Stop called")
	return nil
}
