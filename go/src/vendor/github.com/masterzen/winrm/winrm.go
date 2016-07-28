/*
Copyright 2013 Brice Figureau

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"os"

	"github.com/masterzen/winrm/winrm"
)

func main() {
	var (
		hostname string
		user     string
		pass     string
		cmd      string
		port     int
		https    bool
		insecure bool
		cacert   string
	)

	flag.StringVar(&hostname, "hostname", "localhost", "winrm host")
	flag.StringVar(&user, "username", "vagrant", "winrm admin username")
	flag.StringVar(&pass, "password", "vagrant", "winrm admin password")
	flag.IntVar(&port, "port", 5985, "winrm port")
	flag.BoolVar(&https, "https", false, "use https")
	flag.BoolVar(&insecure, "insecure", false, "skip SSL validation")
	flag.StringVar(&cacert, "cacert", "", "CA certificate to use")
	flag.Parse()

	var certBytes []byte
	var err error
	if cacert != "" {
		certBytes, err = ioutil.ReadFile(cacert)
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}
	} else {
		certBytes = nil
	}

	cmd = flag.Arg(0)
	client, err := winrm.NewClient(&winrm.Endpoint{Host: hostname, Port: port, HTTPS: https, Insecure: insecure, CACert: &certBytes}, user, pass)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	exitCode, err := client.RunWithInput(cmd, os.Stdout, os.Stderr, os.Stdin)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	os.Exit(exitCode)
}
