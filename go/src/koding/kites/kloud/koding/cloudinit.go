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
hostname: '{{.Hostname}}'

bootcmd:
  - [sh, -c, 'echo "127.0.0.1 {{.Hostname}}" >> /etc/hosts']

users:
  - default
  - name: '{{.Username}}'
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

  # README.md
  - content: |
      ## Welcome to Koding...You've said goodbye to locahost!

      Koding is a cloud-based development platform that allows you to:
      - Develop applications in the cloud
      - collaborate with others in real-time
      - learn through interation with a community of like-minded developers

      Koding VMs run Ubuntu 14.04 and are fully functional development
      machines where you can write code in any programming language
      that is supported by Ubuntu/Linux. Things like ruby, perl, gcc,
      python, php, go, node are preinstalled on your VM. You can start
      writing code right away without the need for new installs!

      Here are a few additional commonly asked questions. For more, head
      over to Koding University at http://learn.koding.com

      Some things to note:
      - The default web server root is linked to /home/{{ .Username }}/Web
        so any file placed inside that directory will automatically
        be visible from this URL:
        http://{{.UserDomain}}

      - You can access this VM using any sub-domains that you may have
        set up. To learn more about sub-domains and how to set them up,
        please read this article on Koding University:
        http://learn.koding.com/domains

      - To run a command as the ` + "`" + `root` + "`" + ` user, prefix any command with
        ` + "`" + `sudo <command>` + "`" + `. Remember, with great power, comes great
        responsibility! :)

      Common questions:
      ================
      # How can I find out which packages are installed on my VM?

      Run the command: ` + "`" + `dpkg --get-selections | grep -v deinstall` + "`" + ` to get
      a list of all installed packages. If a particular package is not
      installed, go ahead and install it using ` + "`" + `sudo apt-get install
      <package name>` + "`" + `. Using this command you can install databases like
      postgres, MySQL, Mongo, etc.

      # What is my sudo password?

      By default, you sudo password is blank. Most people like it that
      way but if you prefer, you can use the ` + "`" + `sudo passwd` + "`" + ` command and
      change the default (blank) password to something more secure.

      # How do I poweroff my VM?
      For our free acccounts, the VMs will power off automatically after
      60 minutes of inactivity. However, if you wish to poweroff your
      VM manually, please use the VM settings panel to achieve that.


      For more questions and FAQ, head over to http://learn.koding.com
      or send us an email at support@koding.com
    path: /home/{{.Username}}/README.md
    owner: {{.Username}}:{{.Username}}


{{if .ShouldMigrate }}
  # User migration script (~/migrate.sh)
  - content: |
      #!/bin/bash
      username={{.Username}}
      credentials=({{.Passwords}})
      vm_names=({{.VmNames}})
      vm_ids=({{.VmIds}})
      count=$((${#credentials[@]} - 1))
      counter=0
      clear
      if [ -f /etc/koding/.kodingart.txt ]; then
        cat /etc/koding/.kodingart.txt
      fi
      echo
      echo 'This migration assistant will help you move your VMs from the old Koding'
      echo 'environment to the new one. For each VM that you have, we will copy your'
      echo 'home directory from the old VM into a Backup directory on the new one.'
      echo
      echo 'Please note:'
      echo '  - This script will copy changed files on the old VM and place them in '
      echo '    the Backup directory of the new VM'
      echo '  - This script will NOT install or configure any software'
      echo '  - This script will NOT place any files outside your home directory.'
      echo '    You will need to move those files yourself.'
      echo '  - This script will NOT start any servers or configure any ports.'
      echo
      if [[ ${#vm_names[@]} -eq 1 ]]; then
        index=0
        confirm=''
        while true; do
          read -p "Do you wish to continue?" yn
          case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
          esac
        done
      else
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
      fi
      vm_name="${vm_names[$index]}"
      echo
      echo "Downloading files from $vm_name (this could take a while)..."
      echo
      archive="$vm_name.tgz"
      status=$(echo "-XPOST -u $username:${credentials[$index]} -d vm=${vm_ids[$index]} -s -w %{http_code} --insecure https://migrate.sj.koding.com:3000/export-files" -o $archive | xargs curl)
      if [[ $status -eq 412 ]]; then
        echo "Your VM is still running on old.koding.com. Please log in and "
        echo "turn off your VM by running the command $ sudo poweroff"
        exit 1
      elif [[ $status -ne 200 ]]; then
        error=$(cat $archive)
        rm $archive
        echo "An error occured: $error"
        echo
        echo "Migration failed. Try again or contact support@koding.com"
        echo
        exit 1
      fi
      echo "Extracting your files to directory $(pwd)/$vm_name..."
      mkdir -p Backup/$vm_name
      tar -xzvf $archive -C Backup/$vm_name --strip-components=1 > /dev/null
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
	UserDomain      string
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
