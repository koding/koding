package main

import (
	"koding/tunnel"
	"log"
	"net/http"
)

var serverAddr = "127.0.0.1:7000"

func main() {
	server := tunnel.NewServer()

	// tunnel 127.0.0.1 addresses to the user arslan
	server.AddHost("127.0.0.1:7000", "arslan")

	log.Println("server started at", serverAddr)
	http.Handle("/", server)
	err := http.ListenAndServe(serverAddr, nil)
	if err != nil {
		log.Println(err)
	}
}
