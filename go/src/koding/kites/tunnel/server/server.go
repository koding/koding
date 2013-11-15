package main

import (
	"koding/kites/tunnel/conn"
	"log"
	"net"
	"os"
)

var serverAddr = "127.0.0.1:6000"

func init() {
	log.SetOutput(os.Stdout)
	log.SetPrefix("tunnel-server ")
}

func main() {
	listener, err := net.Listen("tcp", serverAddr)
	if err != nil {
		log.Println("listen server err", err)
	}

	log.Println("server started", listener.Addr())

	for {
		c, err := listener.Accept()
		if err != nil {
			log.Println("accept err: %s", err)
			continue
		}

		log.Println("connected ", c.RemoteAddr())
		go handleConnection(c)
	}

}

func handleConnection(localConn net.Conn) {
	listener, err := net.Listen("tcp4", ":0")
	if err != nil {
		log.Println("listen public err", err)
	}
	log.Println("new listener on ", listener.Addr())

	for {
		publicCon, err := listener.Accept()
		if err != nil {
			log.Println("accept err: %s", err)
			continue
		}

		go conn.Join(localConn, publicCon)
	}
}
