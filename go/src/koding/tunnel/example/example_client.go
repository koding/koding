package main

import (
	"flag"
	"koding/tunnel"
)

var serverAddr = "127.0.0.1:7000"

var port = flag.String("port", "5000", "port to bind to local server")

func main() {
	flag.Parse()
	client := tunnel.NewClient(serverAddr, ":"+*port)
	client.Proxy()
}
