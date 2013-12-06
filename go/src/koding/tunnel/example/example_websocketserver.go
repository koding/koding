package main

import (
	"fmt"
	"io"
	"log"
	"net/http"

	"code.google.com/p/go.net/websocket"
)

// Echo the data received on the WebSocket.
func EchoServer(ws *websocket.Conn) {
	log.Println("echo is served")
	io.Copy(ws, ws)
}

func MainServer(ws *websocket.Conn) {
	fmt.Println("connected", ws.RemoteAddr())
	for {
		var msg string
		if err := websocket.Message.Receive(ws, &msg); err != nil {
			log.Println("err receiver", err)
			return
		}
		fmt.Println("got msg", msg)

		websocket.Message.Send(ws, msg)
	}
}

// This example demonstrates a trivial echo server.
func main() {
	http.Handle("/echo", websocket.Handler(EchoServer))
	http.Handle("/", websocket.Handler(MainServer))
	err := http.ListenAndServe(":5000", nil)
	if err != nil {
		panic("ListenAndServe: " + err.Error())
	}
}
