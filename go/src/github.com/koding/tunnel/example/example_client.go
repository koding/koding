package main

import (
	"flag"
	"koding/tunnel"
)

var port = flag.String("port", "5000", "port to bind to local server")
var serverAddr = flag.String("server", "localhost:7000", "bind to server, addr:port")

func main() {
	flag.Parse()

	client := tunnel.NewClient(*serverAddr, ":"+*port)
	client.Start("arslan")
}
