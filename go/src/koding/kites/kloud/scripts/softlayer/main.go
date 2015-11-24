package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/scripts/softlayer/userdata"
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

	if err := os.MkdirAll("/etc/kite", 0755); err != nil {
		return err
	}

	if err := ioutil.WriteFile("/etc/kite/kite.key", []byte(val.KiteKey), 0644); err != nil {
		return err
	}

	if err := installKlient(val.LatestKlientURL); err != nil {
		return err
	}

	return nil
}

func installKlient(url string) error {
	var tmpFile = "/tmp/latest-klient.deb"
	var args = []string{url, "--retry-connrefused", "--tries", "5", "-O", tmpFile}

	download := exec.Command("wget", args...)
	download.Stdout = os.Stdout
	download.Stderr = os.Stderr
	download.Stdin = os.Stdin
	if err := download.Run(); err != nil {
		return err
	}

	install := exec.Command("dpkg", "-i", tmpFile)
	install.Stdout = os.Stdout
	install.Stderr = os.Stderr
	install.Stdin = os.Stdin
	return install.Run()
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
