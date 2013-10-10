// Demonstrates the use of Replier.
// Prints incoming messages and echoes back to Requester.
package main

import (
	"fmt"
	"koding/messaging/moh"
)

func echo(message []byte) []byte {
	fmt.Println(string(message))
	return message
}

func main() {
	moh.NewReplier("localhost:18500", echo)
	select {}
}
