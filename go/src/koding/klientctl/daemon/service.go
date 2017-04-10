package daemon

import (
	"bytes"
	"fmt"
	"io/ioutil"
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

export USERNAME=${USERNAME:-{{.Username}}}
{{if .KlientPath}}
export KLIENT_BIN=${KLIENT_BIN:-{{.KlientPath}}}
{{else}}
export KLIENT_BIN=${KLIENT_BIN:-/opt/kite/klient/klient}
{{end}}
export HOME=$(eval cd ~${USERNAME}; pwd)
export PATH=$PATH:/usr/local/bin

sudo -E -u "${USERNAME}" ${KLIENT_BIN}
`))

// service provides a preconfigured (based on klientctl's config)
// service object to install, uninstall, start and stop Klient.
func (d *Details) service() (service.Service, error) {
	svcConfig := &service.Config{
		Name:        "klient",
		DisplayName: "klient",
		Description: "Koding Service Connector",
		Executable:  d.Files["klient.sh"],
		Option: map[string]interface{}{
			"LogStderr":     true,
			"LogStdout":     true,
			"After":         "network.target",
			"RequiredStart": "$network",
			"LogFile":       true,
			"Environment": map[string]string{
				"USERNAME": konfig.CurrentUser.Username,
			},
		},
	}

	return service.New(&serviceProgram{}, svcConfig)
}

// klientSh implements methods for creating the klient.sh file.
type klientSh struct {
	// Username that the sudo command will run under.
	Username string

	// KlientPath is the path of klient executable.
	KlientPath string

	// KlientShPath is the path of klient helper script.
	KlientShPath string
}

// Create writes the content of klientSh to a file.
func (k *klientSh) Create() error {
	var buf bytes.Buffer

	if err := klientShTmpl.Execute(&buf, k); err != nil {
		return err
	}

	return ioutil.WriteFile(k.KlientShPath, buf.Bytes(), 0755)
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
