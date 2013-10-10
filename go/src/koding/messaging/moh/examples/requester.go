// Demonstrates the use of Requester.
// Reads lines from stdin and sends to Replier as messages.
// Prints the replies to stdout.
package main

import (
	"bufio"
	"fmt"
	"koding/messaging/moh"
	"os"
)

func main() {
	req, _ := moh.NewRequester("http://localhost:18500")
	bio := bufio.NewReader(os.Stdin)

	for {
		line, _, _ := bio.ReadLine()
		rep, _ := req.Request(line)
		fmt.Println(string(rep))
	}
}
