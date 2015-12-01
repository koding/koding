package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"koding/kites/kloud/scripts/softlayer/userdata"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

const (
	// metadataURL is used to retrieve the custom data we pass when we create a new
	// SoftLayer instance
	metadataURL = "https://api.service.softlayer.com/rest/v3/SoftLayer_Resource_Metadata/getUserMetadata.txt"

	outputFile = "/var/log/koding-setup.txt"
)

// output defines the log and command execution outputs
var output io.Writer = os.Stderr

func main() {
	file, err := os.OpenFile(outputFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Println("couldn't crate file, going to log to stdout")
	} else {
		output = file
	}

	log.SetOutput(output)

	if err := realMain(); err != nil {
		log.Fatalln(err)
	}
}

func realMain() error {
	val, err := metadata()
	if err != nil {
		return err
	}

	log.Println("---- Metadata ----")
	log.Printf("%+v\n", val)

	log.Println(">> Creating /etc/kite folder")
	if err := os.MkdirAll("/etc/kite", 0755); err != nil {
		return err
	}

	log.Println(">> Creating /etc/kite/kite.key file")
	if err := ioutil.WriteFile("/etc/kite/kite.key", []byte(val.KiteKey), 0644); err != nil {
		return err
	}

	log.Printf(">> Creating user '%s' with groups: %+v\n", val.Username, val.Groups)
	if err := createUser(val.Username, val.Groups); err != nil {
		return err
	}

	log.Println(">> Installing klient from URL: %s", val.LatestKlientURL)
	if err := installKlient(val.Username, val.LatestKlientURL); err != nil {
		return err
	}

	return nil
}
func createUser(username string, groups []string) error {
	var args = []string{"--disabled-password", "--shell", "/bin/bash", "--gecos", "Koding", username}
	adduser := newCommand("adduser", args...)
	if err := adduser.Run(); err != nil {
		return err
	}

	for _, groupname := range groups {
		addGroup := newCommand("adduser", username, groupname)
		if err := addGroup.Run(); err != nil {
			return err
		}
	}

	f, err := os.OpenFile("/etc/sudoers", os.O_APPEND|os.O_WRONLY, 0400)
	if err != nil {
		return err
	}
	defer f.Close()

	if _, err := f.WriteString(fmt.Sprintf("%s ALL=(ALL) NOPASSWD:ALL", username)); err != nil {
		return err
	}

	return nil
}

func installKlient(username, url string) error {
	var tmpFile = "/tmp/latest-klient.deb"
	var args = []string{url, "--retry-connrefused", "--tries", "5", "-O", tmpFile}

	log.Println(">> Downloading klient")
	download := newCommand("wget", args...)
	if err := download.Run(); err != nil {
		return err
	}
	defer os.Remove(tmpFile)

	log.Println(">> Installing deb package via dpkg")
	install := newCommand("dpkg", "-i", tmpFile)
	if err := install.Run(); err != nil {
		return err
	}

	log.Println(">> Replacing and updating /etc/init/klient.conf file")
	content, err := ioutil.ReadFile("/etc/init/klient.conf")
	if err != nil {
		return err
	}

	newContent := strings.Replace(string(content), "./klient", fmt.Sprintf("sudo -E -u %s ./klient", username), -1)

	if err := ioutil.WriteFile("/etc/init/klient.conf", []byte(newContent), 0644); err != nil {
		return err
	}

	log.Println(">> Restarting klient")
	restart := newCommand("service", "klient", "restart")
	if err := restart.Run(); err != nil {
		return err
	}

	return nil
}

func metadata() (*userdata.Value, error) {
	resp, err := http.Get(metadataURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var val userdata.Value
	if err := json.NewDecoder(resp.Body).Decode(&val); err != nil {
		return nil, err
	}

	return &val, nil
}

func newCommand(name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.Stdout = output
	cmd.Stderr = output
	cmd.Stdin = os.Stdin
	return cmd
}
