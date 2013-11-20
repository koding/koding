package main

import (
	"koding/tunnel"
)

var serverAddr = "127.0.0.1:7000"
var localAddr = "127.0.0.1:5000"

func main() {
	client := tunnel.NewClient(serverAddr, localAddr)
	client.Proxy()
}
