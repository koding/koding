// Demonstrates the use of CloseableServer.
package main

import (
	"koding/messaging/moh"
	"log"
	"time"
)

func main() {
	s := moh.NewCloseableServer()

	log.Println("Starting server")
	go s.ListenAndServe("127.0.0.1:18500")

	<-time.After(1 * time.Second)

	log.Println("Closing server")
	s.Close()

	<-time.After(1 * time.Second)
}
