package main

import (
	"flag"
	"koding/tunnel"
	"log"
	"net/http"
)

var port = flag.String("port", "7000", "port to bind to itself")

func main() {
	flag.Parse()

	server := tunnel.NewServer()

	// tunnel these addresses to the user arslan
	server.AddHost("127.0.0.1:7000", "arslan")
	server.AddHost("fatih.test.arslan.kd.io", "arslan")

	log.Printf("server started at localhost:%s\n", *port)
	http.Handle("/", server)

	err := http.ListenAndServe(":"+*port, nil)
	if err != nil {
		log.Println(err)
	}
}
