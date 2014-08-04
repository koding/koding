package provisioner

import (
	"encoding/json"
	"fmt"
	"hash/crc32"

	"github.com/mitchellh/packer/packer"
)

var shellProvisioner = map[string]interface{}{
	"type": "shell",
	"inline": []string{
		"sleep 30",
		// Refresh package entries
		"sudo apt-get update",
		// Install system software & CLI Tools
		"sudo apt-get install -y ubuntu-standard ubuntu-minimal htop git net-tools aptitude apache2 php5 libapache2-mod-php5 php5-cgi ruby screen fish sudo emacs mc iotop iftop software-properties-common libgd2-xpm",
		// Install NodeJS 0.10.26
		"wget -O - http://nodejs.org/dist/v0.10.26/node-v0.10.26-linux-x64.tar.gz | sudo tar -C /usr/local/ --strip-components=1 -zxv",
		// Install programming language runtimes/compilers
		"sudo apt-get install -y erlang ghc swi-prolog clisp ruby-dev ri rake python mercurial subversion cvs bzr default-jdk golang-go",
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
			Type:      "shell",
			RawConfig: shellProvisioner,
		},
	},
}

// Ami returns the name of the image associated to the current packer configuration
func Ami() string {
	return "koding-" + Checksum()
}

// Checksum returns an hexadecimal checksum. We use this to ensure idempotence and that an image is only created once
func Checksum() string {
	// Get json representation of packer conf
	// (we could use "gob" encoding any other, json specifically doesn't matter)
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
