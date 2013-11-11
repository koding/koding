// Demonstrates the use of Replier.
// Prints incoming messages and echoes back to Requester.
package main

import (
	"fmt"
	"koding/messaging/moh"
	"net/http"
)

func echo(message []byte) []byte {
	fmt.Println(string(message))
	return append([]byte("REPLY: "), message...)
	// return "REPLY: " + message
}

func main() {
	rep := moh.NewReplier(echo)
	http.ListenAndServe("127.0.0.1:18500", rep)
}
