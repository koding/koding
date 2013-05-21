package main

import "fmt"
import zmq "github.com/alecthomas/gozmq"

func main() {
	context, _ := zmq.NewContext()
	socket, _ := context.NewSocket(zmq.REQ)
	socket.Connect("tcp://127.0.0.1:5000")
	socket.Connect("tcp://127.0.0.1:6000")

	for i := 0; i < 10; i++ {
		msg := fmt.Sprintf("msg %d", i)
		socket.Send([]byte(msg), zmq.SNDMORE)
		println("Sending", msg)
	}
	socket.Send([]byte{}, 0)
	socket.Recv(0)
}
