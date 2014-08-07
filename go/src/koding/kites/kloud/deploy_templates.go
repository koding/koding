package main

import (
	"html/template"
)

var (
	hostsTemplate = template.Must(template.New("hosts").Parse(hosts))

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
)
