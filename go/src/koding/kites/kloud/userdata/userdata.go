package userdata

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/keycreator"
	"log"
	"strings"
	"text/template"

	"code.google.com/p/go.crypto/ssh"
	"gopkg.in/yaml.v2"
)

type Userdata struct {
	Keycreator *keycreator.Key
	Bucket     *Bucket
}

// CloudInitConfig is used as source for the cloudInit template.
type CloudInitConfig struct {
	Username        string
	UserSSHKeys     []string
	Hostname        string
	KiteKey         string
	LatestKlientURL string // URL of the latest version of the Klient package
	ApachePort      int    // Defines the base apache running port, should be 80 or 443
	KitePort        int    // Defines the running kite port, like 3000
	KiteId          string
}

var (
	DefaultApachePort = 80
	DefaultKitePort   = 3000

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
    lock_passwd: True
    gecos: Koding
    groups: docker,sudo
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash

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

runcmd:
  # Configure the bash prompt. XXX: Sometimes /etc/skel/.bashrc is not honored when creating a new user.
  - [sh, -c, 'cp /etc/skel/.bashrc /root/.bashrc']
  - [sh, -c, 'cp /etc/skel/.bashrc /home/ubuntu/.bashrc']
  - [sh, -c, 'cp /etc/skel/.bashrc /home/{{.Username}}/.bashrc']

  # Install & Configure klient
  - [wget, "{{.LatestKlientURL}}", --retry-connrefused, --tries, 5, -O, /tmp/latest-klient.deb]
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

func (u *Userdata) Create(c *CloudInitConfig) ([]byte, error) {
	var err error
	c.KiteKey, err = u.Keycreator.Create(c.Username, c.KiteId)
	if err != nil {
		return nil, err
	}

	latestKlientPath, err := u.Bucket.LatestDeb()
	if err != nil {
		return nil, err
	}

	c.LatestKlientURL = u.Bucket.URL(latestKlientPath)

	if c.ApachePort == 0 {
		c.ApachePort = DefaultApachePort
	}

	if c.KitePort == 0 {
		c.KitePort = DefaultKitePort
	}

	// validate the public keys
	validatedKeys := make([]string, 0)
	for _, key := range c.UserSSHKeys {
		_, _, _, _, err := ssh.ParseAuthorizedKey([]byte(key))
		if err != nil {
			log.Print(`User (%s) has an invalid public SSH key. Not adding it to the authorized keys. Key: %s. Err: %v`,
				c.Username, key, err)
			continue
		}

		validatedKeys = append(validatedKeys, key)
	}

	c.UserSSHKeys = validatedKeys

	var udata bytes.Buffer
	err = cloudInitTemplate.Funcs(funcMap).Execute(&udata, c)
	if err != nil {
		return nil, err
	}

	// validate the udata first before sending
	if cloudErr := yaml.Unmarshal(udata.Bytes(), struct{}{}); cloudErr != nil {
		// write to temporary file so we can see the yaml file that is not
		// formatted in a good way.
		f, err := ioutil.TempFile("", "kloud-cloudinit")
		if err == nil {
			if _, err := f.WriteString(udata.String()); err != nil {
				log.Printf("Cloudinit temporary field couldn't be written %v", err)
			}
		}

		log.Printf("Cloudinit template is not a valid YAML file: %v. YAML file path: %s",
			cloudErr, f.Name())
		return nil, fmt.Errorf("Cloudinit template is not a valid YAML file. Debugfile: %s", f.Name())
	}

	return udata.Bytes(), nil
}
