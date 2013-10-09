// Demonstrates the use of Subscriber.
// Prints incoming messages.
package main

import (
	"fmt"
	"koding/messaging/moh"
)

func echo(message []byte) []byte {
	fmt.Println(string(message))
	return nil
}

func main() {
	moh.NewSubscriber("localhost:18500", echo)
	select {}
}
