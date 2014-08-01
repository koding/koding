package provisioner

import (
	"encoding/json"
	"fmt"
	"hash/crc32"

	"github.com/mitchellh/packer/packer"
)

var	shellProvisioner = map[string]interface{}{
	"type": "shell",
	"inline": []string{
		"sleep 30",
		"sudo apt-get update",
		"sudo apt-get install -y ubuntu-standard ubuntu-minimal htop git net-tools aptitude apache2 php5 libapache2-mod-php5 php5-cgi ruby screen fish sudo emacs mc iotop iftop nodejs software-properties-common libgd2-xpm",
		"sudo apt-get install -y erlang ghc swi-prolog clisp ruby-dev ri rake python mercurial subversion cvs bzr default-jdk",
	},
}

// RawData is JSON abstraction mapped to Go struct. This can be
// Marshaled and injected directly into packer.ParseTemplate()
var RawData = []interface{}{
	shellProvisioner,
}

// PackerTemplate is ready to used and unmarshalled packer.Template. This is
// created only for future references where we might decide to not use
// packer.ParseTemplate()
var PackerTemplate = packer.Template{
	Provisioners: []packer.RawProvisionerConfig{
		{
			Type: "shell",
			RawConfig: shellProvisioner,
		},
	},
}

// Get the AMI name of the image associated to the current packer conf
func Ami() string {
	return "koding-"+Checksum()
}

// Get a hexadecimal checksum
// We use this to ensure idempotence
// and that an image is only crated once
func Checksum() string {
	// Get json representation of docker conf
	data, err := json.Marshal(RawData)
	if err != nil {
		// this should never happen
		panic("Failed to compute Checksum for packer config")
	}

	// integet checksum
	sum := crc32.ChecksumIEEE(data)

	return hex32(sum)
}

// Utility function to produce a hexadecimal string from an uint32
func hex32(x uint32) string {
	return fmt.Sprintf("%08x", x)
}

