// Demonstrates the use of Publisher.
// Reads lines from stdin and sends to Subscriber as messages.
package main

import (
	"bufio"
	"koding/messaging/moh"
	"net/http"
	"os"
)

func main() {
	pub := moh.NewPublisher()
	go http.ListenAndServe("127.0.0.1:18500", pub)

	bio := bufio.NewReader(os.Stdin)
	for {
		line, _, _ := bio.ReadLine()
		pub.Broadcast(line)
	}
}
