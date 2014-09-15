package koding

import (
	"strings"
	"text/template"

	"koding/db/mongodb/modelhelper"
	"koding/migrators/useroverlay/token"
)

var (
	cloudInitTemplate = template.Must(template.New("cloudinit").Parse(cloudInit))

	// TODO: write_files directive doesn't work properly. So we are echoing.
	cloudInit = `
#cloud-config
output : { all : '| tee -a /var/log/cloud-init-output.log' }
disable_root: false
disable_ec2_metadata: true
hostname: {{.Hostname}}

bootcmd:
  - [sh, -c, 'echo "127.0.0.1 {{.Hostname}}" >> /etc/hosts']

users:
  - default
  - name: {{.Username}}
    groups: sudo
    shell: /bin/bash
    gecos: koding user
    lock-password: true
    sudo: ALL=(ALL) NOPASSWD:ALL

write_files:
  # Apache configuration (/etc/apache2/sites-available/000-default.conf)
  - content: |
      <VirtualHost *:{{.ApachePort}}>
        ServerAdmin webmaster@localhost

        # Rewrite scheme to ws otherwise apache can't do a websocket proxy
        RewriteEngine on
        RewriteCond %{HTTP:UPGRADE} ^WebSocket$ [NC]
        RewriteCond %{HTTP:CONNECTION} ^Upgrade$ [NC]
        RewriteRule .* ws://localhost:{{.KitePort}}%{REQUEST_URI} [P]

        # Proxy /kite path to our klient kite
        ProxyRequests Off
        ProxyPass /kite http://localhost:{{.KitePort}}/kite keepalive=On
        ProxyPassReverse /kite http://localhost:{{.KitePort}}/kite

        DocumentRoot /var/www
        <Directory />
          Options +FollowSymLinks
          AllowOverride None
        </Directory>
        <Directory /var/www/>
          Options +Indexes +FollowSymLinks +MultiViews +ExecCGI
          AddHandler cgi-script .cgi .pl .rb .py
          AllowOverride All
          Order allow,deny
          Allow from all
        </Directory>

        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
          AllowOverride None
          Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
          Order allow,deny
          Allow from all
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog ${APACHE_LOG_DIR}/access.log combined
      </VirtualHost>
    path: /etc/apache2/sites-available/000-default.conf

  # User migration script (~/migrate.sh)
  - content: |
      #!/bin/bash
      username={{ .Username }}
      credentials=({{ .Passwords }})
      vm_names=({{ .VmNames }})
      vm_ids=({{ .VmIds }})
      count=$((${#credentials[@]} - 1))
      counter=0
      if [[ ${vm_names[@]} -eq 0 ]]; then
        echo "You don't have any VM to operate on."
        exit 1
      fi
      echo
      echo "We've upgraded your VM! Please follow the instructions below to transfer files from your old VM."
      echo
      echo "VMs:"
      echo
      for vm in "${vm_names[@]}"; do
        echo " - [$counter] $vm"
        let counter=counter+1
      done
      echo
      index=''
      while [[ ! $index =~ ^[0-9]+$ || $index -ge $counter ]]; do
        echo -n "Which vm would you like to migrate? (0-$count) "
        read index
      done
      vm_name="${vm_names[$index]}"
      echo
      echo "Downloading files from $vm_name..."
      echo
      archive="${vm_names[$index]}.tgz"
      echo "-XPOST -u $username:${credentials[$index]} -d vm=${vm_ids[$index]} --insecure https://kontainer12.sj.koding.com:3000/export-files" | xargs curl > $archive
      echo
      echo "Extracting your files to directory $(pwd)/$vm_name..."
      mkdir $vm_name > /dev/null 2>&1
      tar -xzvf $archive -C $vm_name --strip-components 1 > /dev/null 2>&1
      rm $archive
      echo
      echo "Done."
    path: /home/{{.Username}}/migrate.sh
    permissions: '0755'
    owner: {{.Username}}:{{.Username}}

runcmd:
  # Create kite.key
  - [mkdir, "/etc/kite"]
  - [sh, -c, 'echo "{{.KiteKey}}" >> /etc/kite/kite.key']

  # Install & Configure klient
  - [wget, "{{.LatestKlientURL}}", -O, /tmp/latest-klient.deb]
  - [dpkg, -i, /tmp/latest-klient.deb]
  - [chown, -R, '{{.Username}}:{{.Username}}', /opt/kite/klient]
  - service klient stop
  - [sed, -i, 's/\.\/klient/sudo -E -u {{.Username}} \.\/klient/g', /etc/init/klient.conf]
  - service klient start
  - [rm, -f, /tmp/latest-klient.deb]

  # Configure user's home directory
  - [sh, -c, 'cp -r /opt/koding/userdata/* /home/{{.Username}}/']
  - [chown, -R, '{{.Username}}:{{.Username}}', /home/{{.Username}}/]
  - [chmod, +x, /home/{{.Username}}/Web/perl.pl]
  - [chmod, +x, /home/{{.Username}}/Web/python.py]
  - [chmod, +x, /home/{{.Username}}/Web/ruby.rb]
  - [rm, -rf, /opt/koding/userdata]

  # Configure Apache to serve user's web content
  - [rm, -rf, /var/www]
  - [ln, -s, /home/{{.Username}}/Web, /var/www]
  - a2enmod cgi
  - service apache2 restart


final_message: "All done!"
`
)

type CloudInitConfig struct {
	Username        string
	Hostname        string
	KiteKey         string
	LatestKlientURL string // URL of the latest version of the Klient package
	ApachePort      int    // Defines the base apache running port, should be 80 or 443
	KitePort        int    // Defines the running kite port, like 3000

	// Needed for migrate.sh script
	Passwords string
	VmNames   string
	VmIds     string
}

func (c *CloudInitConfig) setupMigrateScript() error {
	vms, err := modelhelper.GetUserVMs(c.Username)
	if err != nil {
		return err
	}
	if len(vms) == 0 {
		return nil
	}

	passwords := make([]string, len(vms))
	vmIds := make([]string, len(vms))
	vmNames := make([]string, len(vms))

	for _, vm := range vms {
		id := vm.Id.Hex()
		passwords = append(passwords, token.StringToken(c.Username, id))
		vmIds = append(vmIds, id)
		vmNames = append(vmNames, vm.HostnameAlias)
	}

	c.Passwords = strings.Join(passwords, " ")
	c.VmIds = strings.Join(vmIds, " ")
	c.VmNames = strings.Join(vmNames, " ")

	return nil
}
