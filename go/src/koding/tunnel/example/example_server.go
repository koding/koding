package main

import (
	"koding/tunnel"
	"log"
	"net/http"
)

var serverAddr = "127.0.0.1:7000"

func main() {
	server := tunnel.NewServer()

	http.HandleFunc("/", server.TunnelHandler)
	log.Println("server started at", serverAddr)
	err := http.ListenAndServe(serverAddr, nil)
	if err != nil {
		log.Println(err)
	}
}
