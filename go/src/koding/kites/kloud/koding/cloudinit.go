package koding

import (
	"fmt"
	"strings"
	"text/template"

	"koding/db/mongodb/modelhelper"
	"koding/migrators/useroverlay/token"
)

var (
	// funcMap contains easy to use template functions
	funcMap = template.FuncMap{
		"user_keys": func(keys []string) string {
			if len(keys) == 0 {
				return ""
			}

			c := "ssh_authorized_keys:\n"
			for _, key := range keys {
				c += fmt.Sprintf("  - %s\n", strings.TrimSpace(key))
			}
			return c
		},
	}

	cloudInitTemplate = template.Must(template.New("cloudinit").Funcs(funcMap).Parse(cloudInit))

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


{{ user_keys .UserSSHKeys }}

write_files:
  # Create kite.key
  - content: |
      {{.KiteKey}}
    path: /etc/kite/kite.key

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

{{if .ShouldMigrate }}
  # User migration script (~/migrate.sh)
  - content: |
      #!/bin/bash
      username={{ .Username }}
      credentials=({{ .Passwords }})
      vm_names=({{ .VmNames }})
      vm_ids=({{ .VmIds }})
      count=$((${#credentials[@]} - 1))
      counter=0
      clear
      if [ -f /etc/koding/.kodingart.txt ]; then
        cat /etc/koding/.kodingart.txt
      fi
      echo
      echo 'This migration assistant will help you move your VMs from the old Koding'
      echo 'environment to the new one. For each VM that you have, we will copy your'
      echo 'home directory (and any files you have changed) from the old VM into a'
      echo 'Backup directory on the new one.'
      echo
      echo 'Please note:'
      echo '  - This script will copy changed files on the old VM and place them in '
      echo '    the Backup directory of the new VM'
      echo '  - This script will NOT install or configure any software'
      echo '  - This script will NOT place any files outside your home directory.'
      echo '    You will need to move those files yourself.'
      echo '  - This script will NOT start any servers or configure any ports.'
      echo
      echo "Your VMs:"
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
      echo "Downloading files from $vm_name (this could take a while)..."
      echo
      archive="$vm_name.tgz"
      echo "-XPOST -u $username:${credentials[$index]} -d vm=${vm_ids[$index]} --insecure https://migrate.sj.koding.com:3000/export-files" | xargs curl > $archive
      echo
      echo "Extracting your files to directory $(pwd)/$vm_name..."
      mkdir -p Backup/$vm_name
      tar -xzvf $archive -C Backup/$vm_name --strip-components 1 > /dev/null
      rm $archive
      echo
      echo "You have successfully migrated $vm_name to the new Koding environment."
      echo "The files have been placed in /home/$username/Backup/$vm_name. Please use"
      echo 'the unzip command to access the files and then move or copy them into the'
      echo 'appropriate directories in your new VM.'
      echo
    path: /home/{{.Username}}/migrate.sh
    permissions: '0755'
    owner: {{.Username}}:{{.Username}}
{{end}}

runcmd:
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
	UserSSHKeys     []string
	Hostname        string
	KiteKey         string
	LatestKlientURL string // URL of the latest version of the Klient package
	ApachePort      int    // Defines the base apache running port, should be 80 or 443
	KitePort        int    // Defines the running kite port, like 3000

	// Needed for migrate.sh script
	Passwords     string
	VmNames       string
	VmIds         string
	ShouldMigrate bool

	Test bool
}

func (c *CloudInitConfig) setupMigrateScript() {
	// FIXME: Hack. Revise here.
	if c.Test {
		return
	}
	vms, err := modelhelper.GetUserVMs(c.Username)
	if err != nil {
		return
	}
	if len(vms) == 0 {
		return
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

	c.ShouldMigrate = true
}
