package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
)

const metadataURL = "https://api.service.softlayer.com/rest/v3/SoftLayer_Resource_Metadata/getUserMetadata.txt"

func main() {
	if err := realMain(); err != nil {
		log.Fatalln(err)
	}
}

func realMain() error {
	val, err := metadata()
	if err != nil {
		return err
	}

	fmt.Printf("val = %+v\n", val)

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
	if err := installKlient(val.LatestKlientURL); err != nil {
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

func installKlient(url string) error {
	var tmpFile = "/tmp/latest-klient.deb"
	var args = []string{url, "--retry-connrefused", "--tries", "5", "-O", tmpFile}

	download := newCommand("wget", args...)
	download.Stdout = os.Stdout
	download.Stderr = os.Stderr
	download.Stdin = os.Stdin
	if err := download.Run(); err != nil {
		return err
	}

	install := newCommand("dpkg", "-i", tmpFile)
	return install.Run()
}

func metadata() (*Value, error) {
	resp, err := http.Get(metadataURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var val Value
	if err := json.NewDecoder(resp.Body).Decode(&val); err != nil {
		return nil, err
	}

	return &val, nil
}

func newCommand(name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd
}
