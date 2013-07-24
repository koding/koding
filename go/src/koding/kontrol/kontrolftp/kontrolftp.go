package main

import (
	"fmt"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/config"
	"koding/tools/fastproxy"
	"log"
	"log/syslog"
	"net"
	"strings"
)

var (
	proxyDB *proxyconfig.ProxyConfiguration
	logs    *syslog.Writer
)

func main() {
	fmt.Println("Starting FTP proxy")
	var err error

	logs, err = syslog.New(syslog.LOG_DEBUG|syslog.LOG_USER, "KONTROL_FTP")
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		res := fmt.Sprintf("proxyconfig mongodb connect: %s", err)
		logs.Alert(res)
		log.Fatalln(res)
	}

	err = startFTP()
	if err != nil {
		logs.Alert(err.Error())
		log.Fatalln(err)
	}
}

// startFTP is used to reverse proxy FTP connections on port 21
func startFTP() error {
	logs.Info("ftp mode is enabled. serving at :21...")
	return fastproxy.ListenFTP(&net.TCPAddr{IP: nil, Port: 21}, net.ParseIP(config.Current.Kontrold.Proxy.FTPIP), nil, func(req *fastproxy.FTPRequest) {
		userName := req.User
		vmName := req.User
		if userParts := strings.SplitN(userName, "@", 2); len(userParts) == 2 {
			userName = userParts[0]
			vmName = userParts[1]
		}

		vm, err := proxyDB.GetVM(vmName)
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
