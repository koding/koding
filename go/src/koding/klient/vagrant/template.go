package vagrant

import (
	"bytes"
	"text/template"
)

var (
	vagrantFile = `# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

$script = <<SCRIPT
#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export USER_LOG=/var/log/user-script.log

die() {
	echo "error: $1"
	exit 2
}

echo I am provisioning...
date > /etc/vagrant_provisioned_at
wget -q --retry-connrefused --tries 5 https://s3.amazonaws.com/kodingdev-provision/provisionklient.gz || die "downloading provisionklient failed"
gzip -d -f provisionklient.gz || die "unarchiving provisionklient failed"
chmod +x provisionklient
./provisionklient -data '{{ .ProvisionData }}'

cat >user-script.sh <<EOF
{{ .CustomScript }}
EOF

chmod +x user-script.sh
./user-script.sh 2>&1 | tee -a $USER_LOG || die "$(cat $USER_LOG | perl -pe 's/\n/\\\\n/g')"

SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "{{ .Box }}"
  config.vm.hostname = "{{ .Hostname }}"

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "{{ .Memory }}", "--cpus", "{{ .Cpus }}"]
  end

  config.vm.provision "shell", inline: $script
end
`

	vagrantTemplate = template.Must(template.New("vagrant").Parse(vagrantFile))
)

func createTemplate(opts *VagrantCreateOptions) (string, error) {
	buf := new(bytes.Buffer)
	if err := vagrantTemplate.Execute(buf, opts); err != nil {
		return "", err
	}

	return buf.String(), nil
}
