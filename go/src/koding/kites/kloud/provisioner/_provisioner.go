// This package is not used anymore, however it's just for here because it's
// contains examples for how to integrate packer into a Go application
package provisioner

import (
	"encoding/json"
	"fmt"
	"hash/crc32"

	"github.com/mitchellh/packer/packer"
)

// Must be in current dir
var TemplateDir = "website/"

var shellProvisioner = map[string]interface{}{
	"type": "shell",
	"inline": []string{
		"sleep 30",
		// Refresh package entries
		"sudo apt-get update",
		// Install system software & CLI Tools
		"sudo apt-get install -y ubuntu-standard ubuntu-minimal htop git net-tools aptitude apache2 php5 libapache2-mod-php5 php5-cgi ruby screen fish sudo emacs mc iotop iftop software-properties-common python-fcgi ruby-fcgi",
		// Install NodeJS 0.10.26
		"wget -O - http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz | sudo tar -C /usr/local/ --strip-components=1 -zxv",
		// Install programming language runtimes/compilers
		"sudo apt-get install -y erlang ghc swi-prolog clisp ruby-dev ri rake python mercurial subversion cvs bzr default-jdk golang-go",

		// Load apache modules, those are needed to enable reverse proxy kites
		// and execute cgi scripts
		"sudo a2enmod cgi",
		"sudo a2enmod rewrite",
		"sudo a2enmod proxy",
		"sudo a2enmod proxy_http",
		"sudo a2enmod proxy_wstunnel",
		"sudo a2enmod proxy_fcgi",

		// This is needed for file provisioner which doesn't have sudo access,
		// we need to copy it the files here.
		"mkdir -p /tmp/userdata/Web",

		// Create our user home directory layout, is going to copied later to
		// /home/username and chowned to the users permission. We can't copy
		// them directly to /tmp because it's get purged once the machine is
		// destroyed and during the ami creation
		"sudo mkdir -p /opt/koding/userdata/",
		"sudo mkdir -p /opt/koding/userdata/Web",
		"sudo mkdir -p /opt/koding/userdata/Applications",
		"sudo mkdir -p /opt/koding/userdata/Backup",
		"sudo mkdir -p /opt/koding/userdata/Documents",
	},
}

var fileProvisioner = map[string]interface{}{
	"type":        "file",
	"source":      TemplateDir,
	"destination": "/tmp/userdata/Web",
}

var copyProvisioner = map[string]interface{}{
	"type": "shell",
	"inline": []string{
		// Now copy back from tmp to userdata/web because file provisioner
		// doesn't have access
		"sudo cp -r /tmp/userdata/Web/* /opt/koding/userdata/Web/",
	},
}

// RawData is JSON abstraction mapped to Go struct. This can be
// Marshaled and injected directly into packer.ParseTemplate()
var RawData = []interface{}{
	shellProvisioner,
	fileProvisioner,
	copyProvisioner,
}

// PackerRawData returns a dynamically created packer raw data
func PackerRawData(templateDir string) []interface{} {
	data := []interface{}{}
	data = append(data, shellProvisioner)

	// replace template dir
	if templateDir != "" {
		fileProvisioner["source"] = templateDir
	}
	data = append(data, fileProvisioner)
	data = append(data, copyProvisioner)
	return data
}

// PackerTemplate is ready to used and unmarshalled packer.Template. This is
// created only for future references where we might decide to not use
// packer.ParseTemplate()
var PackerTemplate = packer.Template{
	Provisioners: []packer.RawProvisionerConfig{
		{
			Type:      "shell",
			RawConfig: shellProvisioner,
		},
		{
			Type:      "file",
			RawConfig: fileProvisioner,
		},
		{
			Type:      "shell",
			RawConfig: copyProvisioner,
		},
	},
}

// Ami returns the name of the image associated to the current packer configuration
func Ami() (string, error) {
	checksum, err := Checksum()
	if err != nil {
		return "", err
	}
	return "koding-" + checksum, err
}

// Checksum returns an hexadecimal checksum. We use this to ensure idempotence and that an image is only created once
func Checksum() (string, error) {
	// Get json representation of packer conf
	// (we could use "gob" encoding any other, json specifically doesn't matter)
	data, err := json.Marshal(RawData)
	if err != nil {
		// this should never happen
		return "", err
	}

	// integet checksum
	sum := crc32.ChecksumIEEE(data)

	return hex32(sum), nil
}

// Utility function to produce a hexadecimal string from an uint32
func hex32(x uint32) string {
	return fmt.Sprintf("%08x", x)
}

// // IMAGE BUILDER
// amiName, err := provisioner.Ami()
// if err != nil {
// 	return nil, fmt.Errorf("Could not get generated AMI name: %s", err)
// }
//
// // Build type needed for backer
// a.ImageBuilder.Type = "amazon-ebs"
//
// // SSH username
// a.ImageBuilder.SshUsername = "ubuntu"
//
// // Name of AMI to build if needed
// a.ImageBuilder.AmiName = amiName
//
// // Use this ami as a "foundation"
// a.ImageBuilder.SourceAmi = DefaultBaseAMI
//
// // Region we're building in
// a.ImageBuilder.Region = a.Builder.Region
//
// // Build AMI for this instance type
// // Doesn't need VPC, etc ... and AMI can be used for t2.micro
// // plus the build is faster
// a.ImageBuilder.InstanceType = "m3.medium"
//
// // Credentials
// a.ImageBuilder.AccessKey = a.Creds.AccessKey
// a.ImageBuilder.SecretKey = a.Creds.SecretKey
