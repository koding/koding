// Demonstrates the use of Publisher.
// Reads lines from stdin and sends to Subscriber as messages.
package main

import (
	"bufio"
	"koding/messaging/moh"
	"os"
)

func main() {
	pub, _ := moh.NewPublisher("localhost:18500")
	bio := bufio.NewReader(os.Stdin)

	for {
		line, _, _ := bio.ReadLine()
		pub.Broadcast(line)
	}
}
