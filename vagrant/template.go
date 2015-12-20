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
echo I am provisioning...
date > /etc/vagrant_provisioned_at
wget "https://s3.amazonaws.com/kodingdev-softlayer/softlayer"
chmod +x softlayer
./softlayer -data {{ .ProvisionData }}
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "{{ .Box }}"
  config.vm.hostname = "{{ .Hostname }}"

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "{{ .Memory }}", "--cpus", "{{ .Cpus }}"]
  end

  config.vm.network :forwarded_port, guest: 56789, host: 56790, auto_correct: true
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
