package main

import (
	"text/template"
)

var (
	hostsTemplate       = template.Must(template.New("hosts").Parse(hosts))
	apacheTemplate      = template.Must(template.New("apache").Parse(apache))
	apachePortsTemplate = template.Must(template.New("apachePorts").Parse(apachePorts))

	// default ubuntu /etc/hosts file which is used to replace with our custom
	// hostname later
	hosts = `127.0.0.1       localhost
127.0.1.1       {{.}} {{.}}

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters`

	apache = `
<VirtualHost *:{{.ApachePort}}>
  ServerAdmin webmaster@localhost

  # Rewrite scheme to ws otherwise apache can't do a websocket proxy
  RewriteEngine on
  RewriteCond %{HTTP:UPGRADE} ^WebSocket$ [NC]
  RewriteCond %{HTTP:CONNECTION} ^Upgrade$ [NC]
  RewriteRule .* ws://localhost:3000%{REQUEST_URI} [P]

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
`

	apachePorts = `
Listen {{.ApachePort}}
`
)
