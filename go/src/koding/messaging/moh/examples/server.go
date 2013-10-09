// Demonstrates the use of closeable MessagingServer.
package main

import (
	"koding/messaging/moh"
	"log"
	"time"
)

func main() {
	s, err := moh.NewMessagingServer("127.0.0.1:18500")
	if err != nil {
		log.Fatalln(err)
	}

	log.Println("Starting server")
	go s.Serve()

	<-time.After(1 * time.Second)

	log.Println("Closing server")
	s.Close()

	<-time.After(1 * time.Second)
}
