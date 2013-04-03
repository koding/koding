package main

import (
	"koding/tools/db"
	"koding/tools/fastproxy"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"strings"
)

func main() {
	fastproxy.Listen(&net.TCPAddr{nil, 80}, nil, func(req fastproxy.Request) {
		name := strings.SplitN(req.Host, ".", 2)[0]

		var vm virt.VM
		if err := db.VMs.Find(bson.M{"name": name}).One(&vm); err != nil {
			req.Redirect("http://www.koding.com/notfound.html")
			return
		}

		if vm.IP == nil {
			req.Redirect("http://www.koding.com/notactive.html")
			return
		}

		if err := req.Relay(&net.TCPAddr{IP: vm.IP, Port: 80}); err != nil {
			req.Redirect("http://www.koding.com/notactive.html")
		}
	})
}
