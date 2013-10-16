// Demonstrates the use of Subscriber.
// Prints incoming messages.
package main

import (
	"fmt"
	"koding/messaging/moh"
)

func echo(message []byte) {
	fmt.Println(string(message))
}

func main() {
	sub := moh.NewSubscriber("ws://localhost:18500", echo)
	fmt.Println("Connecting...")
	<-sub.Connect()
	fmt.Println("Connected. Waiting for messages...")
	select {}
}
