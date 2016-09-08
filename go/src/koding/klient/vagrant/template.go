package vagrant

import (
	"bytes"
	"encoding/base64"
	"text/template"
)

var (
	vagrantFile = `# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$script = <<SCRIPT
#!/bin/bash

{{if .Strict}}set -euo pipefail{{end}}

export DEBIAN_FRONTEND=noninteractive
export USER_LOG=/var/log/cloud-init-output.log

die() {
	echo "error: $1"
	exit 2
}

trap 'echo _KD_DONE_' EXIT

{{if .TLSProxyHostname}}
echo 127.0.0.1 {{.TLSProxyHostname}} >> /etc/hosts
{{end}}

echo I am provisioning...
date > /etc/vagrant_provisioned_at
wget -q --retry-connrefused --tries 5 https://koding-provision.s3.amazonaws.com/provisionklient.gz || die "downloading provisionklient failed"
gzip -d -f provisionklient.gz || die "unarchiving provisionklient failed"
chmod +x provisionklient
./provisionklient -data '{{.ProvisionData}}'

mkdir -p /var/lib/koding
cat >/var/lib/koding/user-data.sh <<"EOF"
{{unbase64 .CustomScript}}
EOF

chmod -R 0755 /var/lib/koding

pushd /var/lib/koding
./user-data.sh 2>&1 | tee -a $USER_LOG || die "$(cat $USER_LOG | perl -pe 's/\n/\\\\n/g')"
popd /var/lib/koding

SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "{{.Box}}"
  config.vm.hostname = "{{.Hostname}}"

{{range $_, $f := .ForwardedPorts}}
  config.vm.network "forwarded_port", guest: {{$f.GuestPort}}, host: {{$f.HostPort}}, auto_correct: true
{{end}}

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "{{.Memory}}", "--cpus", "{{.Cpus}}"]
  end

  config.vm.provision "shell", inline: $script
end
`

	vagrantTemplate = template.Must(template.New("vagrant").Funcs(template.FuncMap{
		"unbase64": func(encS string) string {
			if encS == "" {
				return ""
			}

			if decP, err := base64.StdEncoding.DecodeString(encS); err == nil {
				return string(decP)
			}

			return encS
		},
	}).Parse(vagrantFile))
)

func createTemplate(opts *VagrantCreateOptions) (string, error) {
	buf := new(bytes.Buffer)
	if err := vagrantTemplate.Execute(buf, opts); err != nil {
		return "", err
	}

	return buf.String(), nil
}
