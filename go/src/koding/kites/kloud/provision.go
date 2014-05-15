package main

import "github.com/mitchellh/packer/packer"

const (
	klientDeb    = "klient_0.0.1_amd64.deb"
	klientKey    = "kite.key"
	klientKeyDir = "/opt/kite/klient/key"
)

/* KloudProvisioner is a list of packer provisioners that is responsible of
 deploying and setting up a Klient deb, example JSON data is as below:

"provisioners": [
  {
    "type": "file",
    "source": "{{user `klient_deb`}}",
    "destination": "/tmp/{{user `klient_deb`}}"
  },
  {
    "type": "shell",
    "inline": [
      "sleep 30",
      "sudo dpkg -i /tmp/{{user `klient_deb`}}",
      "mkdir -p {{user `klient_keydir`}}"
    ]
  },
  {
    "type": "file",
    "source": "{{user `klient_keyname`}}",
    "destination": "{{user `klient_keydir`}}/{{user `klient_keyname`}}"
  },

*/

// klientProvisioner is JSON abstraction mapped to Go struct. This can be
// Marshaled and injected directly into packer.ParseTemplate()
var klientProvisioner = []interface{}{
	map[string]interface{}{
		"type":        "file",
		"source":      klientDeb,
		"destination": "/tmp/" + klientDeb,
	},
	map[string]interface{}{
		"type": "shell",
		"inline": []string{
			"sleep 30",
			"sudo dpkg -i /tmp/" + klientDeb,
			"mkdir -p " + klientKeyDir,
		},
	},
	map[string]interface{}{
		"type":        "file",
		"source":      klientKey,
		"destination": klientKeyDir + "/" + klientKey,
	},
	map[string]interface{}{
		"type": "shell",
		"inline": []string{
			"service klient restart",
		},
	},
}

// klientTemplate is ready to used and unmarshalled packer.Template. This is
// created only for future references where we might decide to not use
// packer.ParseTemplate()
var klientTemplate = packer.Template{
	Provisioners: []packer.RawProvisionerConfig{
		{
			Type: "file",
			RawConfig: map[string]string{
				"type":        "file",
				"source":      klientDeb,
				"destination": "/tmp/" + klientDeb,
			},
		},
		{
			Type: "shell",
			RawConfig: map[string]interface{}{
				"type": "shell",
				"inline": []string{
					"sleep 30",
					"sudo dpkg -i /tmp/" + klientDeb,
					"mkdir -p " + klientKeyDir,
				},
			},
		},
		{
			Type: "file",
			RawConfig: map[string]string{
				"type":        "file",
				"source":      klientKey,
				"destination": klientKeyDir + "/" + klientKey,
			},
		},
		{
			Type: "shell",
			RawConfig: map[string]interface{}{
				"type": "shell",
				"inline": []string{
					"service klient restart",
				},
			},
		},
	},
}
