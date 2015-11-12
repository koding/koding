package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/fastproxy"
	"log"
	"log/syslog"
	"net"
	"strings"
)

var logs *syslog.Writer
var flagProfile = flag.String("c", "", "Configuration profile from file")

func main() {
	flag.Parse()
	fmt.Println("Starting FTP proxy")
	var err error

	conf := config.MustConfig(*flagProfile)
	modelhelper.Initialize(conf.Mongo)

	logs, err = syslog.New(syslog.LOG_DEBUG|syslog.LOG_USER, "KONTROL_FTP")

	err = startFTP(conf)
	if err != nil {
		logs.Alert(err.Error())
		log.Fatalln(err)
	}
}

// startFTP is used to reverse proxy FTP connections on port 21
func startFTP(conf *config.Config) error {
	logs.Info("ftp mode is enabled. serving at :21...")
	return fastproxy.ListenFTP(&net.TCPAddr{IP: nil, Port: 21}, net.ParseIP(conf.Kontrold.Proxy.FTPIP), nil, func(req *fastproxy.FTPRequest) {
		userName := req.User
		vmName := req.User
		if userParts := strings.SplitN(userName, "@", 2); len(userParts) == 2 {
			userName = userParts[0]
			vmName = userParts[1]
		}

		vm, err := modelhelper.GetVM(vmName)
		if err != nil {
			req.Respond("530 No Koding VM with name '" + vmName + "' found.\r\n")
			return
		}

		logs.Info(fmt.Sprintf("ftp proxy: username: %s vm.IP: %s", userName, vm.IP.String()))
		if err = req.Relay(&net.TCPAddr{IP: vm.IP, Port: 21}, userName); err != nil {
			req.Respond("530 The Koding VM '" + vmName + "' did not respond.")
		}
	})
}
