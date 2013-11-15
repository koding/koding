package main

import (
	"koding/kites/tunnel/conn"
	"log"
	"net"
	"os"
)

var serverAddr = "127.0.0.1:6000"
var localAddr = "127.0.0.1:5000"

func init() {
	log.SetOutput(os.Stdout)
	log.SetPrefix("tunnel-client ")
}

func main() {
	remoteConn, err := net.Dial("tcp", serverAddr)
	if err != nil {
		log.Println("dial remote err: %s", err)
		return
	}
	defer remoteConn.Close()

	localConn, err := net.Dial("tcp", localAddr)
	if err != nil {
		log.Println("dial local err: %s", err)
		return
	}
	defer localConn.Close()

	conn.Join(localConn, remoteConn)
}
