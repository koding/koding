/*
Usage:

1.) Run our proxy handler:

go run proxy-handler.go

or give explicit local and remote path

go run proxy-handler.go -l localhost:8080 -r localhost:9090

2.) Open http://localhost:9999/ which should directed to koding.com

*/

package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"net"
)

var localAddr *string = flag.String("l", "localhost:9999", "local address")
var remoteAddr *string = flag.String("r", "koding.com:80", "remote address")

func main() {
	flag.Parse()

	fmt.Printf("Listening: %v\nProxying: %v\n\n", *localAddr, *remoteAddr)

	addr, err := net.ResolveTCPAddr("tcp", *localAddr)
	if err != nil {
		log.Fatal(err)
	}

	listener, err := net.ListenTCP("tcp", addr)
	if err != nil {
		log.Fatal(err)
	}

	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}

		go handleConnection(conn)
	}
}

func handleConnection(lConn net.Conn) {
	log.Println("got a connection")
	defer lConn.Close()

	rAddr, err := net.ResolveTCPAddr("tcp", *remoteAddr)
	if err != nil {
		log.Println(err)
		return
	}

	rConn, err := net.DialTCP("tcp", nil, rAddr)
	if err != nil {
		log.Println(err)
		rConn.Close()
		return
	}
	defer rConn.Close()

	go io.Copy(rConn, lConn)
	io.Copy(lConn, rConn)

}
