// package provisionklient provisions a machine based on two things. If no
// -data flag is passed it assumes it's inside a Softlayer Virtual Machine and
// tries to get the metadata from the internal service. If a -data flag is
// passed it assumes that it is a base64 encoded JSON and uses it directly
package main

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"koding/kites/kloud/scripts/provisionklient/userdata"
	"log"
	"net/http"
	"os"
	"os/exec"
	"os/user"
	"strconv"
	"strings"
)

const (
	// metadataURL is used to retrieve the custom data we pass when we create a new
	// SoftLayer instance
	metadataURL = "https://api.service.softlayer.com/rest/v3/SoftLayer_Resource_Metadata/getUserMetadata.txt"

	outputFile = "/var/log/koding-setup.txt"
)

var (
	flagData = flag.String("data", "", "Data to be used for provisioning. Must be JSON encoded in base64")

	// output defines the log and command execution outputs
	output io.Writer = os.Stdout
)

func main() {
	file, err := os.OpenFile(outputFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Println("couldn't crate file, going to log to stdout")
	} else {
		output = io.MultiWriter(file, os.Stdout)
	}

	log.SetOutput(output)

	if err := realMain(); err != nil {
		log.Fatalln("ERROR:", err)
	}
}

func realMain() error {
	flag.Parse()

	var val *userdata.Value
	var err error
	if *flagData == "" {
		// get data from metadata if nothing is passed as arguments
		// used by softlayer instances
		val, err = metadata()
		if err != nil {
			return err
		}
	} else {
		data, err := base64.StdEncoding.DecodeString(*flagData)
		if err != nil {
			return err
		}

		// Try to uncompress the payload. If it fails, it was not compressed.
		if cr, err := gzip.NewReader(bytes.NewReader(data)); err == nil {
			p, err := ioutil.ReadAll(cr)
			if err == nil {
				data = p
			}
		}

		if err := json.Unmarshal(data, &val); err != nil {
			return err
		}
	}

	log.Println("---- Metadata ----")
	log.Printf("%+v\n", val)

	log.Println(">> Creating /etc/kite folder")
	if err := os.MkdirAll("/etc/kite", 0755); err != nil {
		return fmt.Errorf("error creating /etc/kite directory: %s", err)
	}

	log.Println(">> Creating /etc/kite/kite.key file")
	if err := ioutil.WriteFile("/etc/kite/kite.key", []byte(val.KiteKey), 0644); err != nil {
		return fmt.Errorf("error writing /etc/kite/kite.key file: %s", err)
	}

	log.Printf(">> Creating user '%s' with groups: %+v\n", val.Username, val.Groups)
	if err := createUser(val.Username, val.Groups); err != nil {
		return fmt.Errorf("error creating %q user: %s", val.Username, err)
	}

	log.Printf(">> Installing klient from URL: %s\n", val.LatestKlientURL)
	if err := installKlient(val); err != nil {
		return fmt.Errorf("error installing klient: %s", err)
	}

	return nil
}

func createUser(username string, groups []string) error {
	var args = []string{"--disabled-password", "--shell", "/bin/bash", "--gecos", "Koding", "--force-badname", username}
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

func lookupUser(username string) (uid, gid int, err error) {
	u, err := user.Lookup(username)
	if err != nil {
		return 0, 0, err
	}

	uid, err = strconv.Atoi(u.Uid)
	if err != nil {
		return 0, 0, err
	}

	gid, err = strconv.Atoi(u.Gid)
	if err != nil {
		return 0, 0, err
	}

	return uid, gid, nil
}

// installKlient(val.Username, val.LatestKlientURL, val.RegisterURL, val.KontrolURL, val.TunnelURL)
// func installKlient(username, url, registerURL, kontrolURL, tunnelURL string) error {
func installKlient(val *userdata.Value) error {
	var tmpFile = "/tmp/latest-klient.deb"
	var args = []string{val.LatestKlientURL, "--retry-connrefused", "--tries", "5", "-O", tmpFile}

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

	initLine := fmt.Sprintf("sudo -E -u %s KITE_HOME=/etc/kite ./klient ", val.Username)
	if val.TunnelName == "" && val.RegisterURL != "" {
		initLine += fmt.Sprintf(" -register-url '%s'", val.RegisterURL)
	}

	if val.KontrolURL != "" {
		initLine += fmt.Sprintf(" -kontrol-url '%s'", val.KontrolURL)
	}

	if val.TunnelName != "" {
		initLine += fmt.Sprintf(" -tunnel-name '%s'", val.TunnelName)
	}

	if val.TunnelKiteURL != "" {
		initLine += fmt.Sprintf(" -tunnel-kite-url '%s'", val.TunnelKiteURL)
	}

	newContent := strings.Replace(string(content), "./klient", initLine, -1)

	if err := ioutil.WriteFile("/etc/init/klient.conf", []byte(newContent), 0644); err != nil {
		return err
	}

	// Ensure the klient is able to update itself.
	uid, gid, err := lookupUser(val.Username)
	if err != nil {
		return err
	}

	for _, path := range []string{"/opt/kite/klient", "/opt/kite/klient/klient"} {
		if err := os.Chown(path, uid, gid); err != nil {
			return err
		}
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
	defer func() {
		if resp != nil && resp.Body != nil {
			resp.Body.Close()
		}
	}()

	if err != nil {
		return nil, err
	}

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
