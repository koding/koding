package moh

import (
	"code.google.com/p/go.net/websocket"
	"log"
	"time"
)

type Subscriber struct {
	ws *websocket.Conn
	h  MessageHandler
}

// NewSubscriber opens a websocket connection to a Publisher and
// returns a pointer to newly created Subscriber.
// After creating a Subscriber you should subscribe to messages with Subscribe function.
func NewSubscriber(addr string, h MessageHandler) (*Subscriber, error) {
	url := "ws://" + addr + "/"
	origin := "http://localhost/" // dont know if this is required
	ws, err := websocket.Dial(url, "", origin)
	if err != nil {
		return nil, err
	}

	sub := &Subscriber{
		ws: ws,
		h:  h,
	}
	go sub.consumer()
	return sub, err
}

// Subscribe registers the Subscriber to receive messages matching with the key.
func (sub *Subscriber) Subscribe(key string) error {
	return websocket.Message.Send(sub.ws, key)
}

func (sub *Subscriber) consumer() {
	for {
		var message []byte
		log.Println("Reading from websocket")
		err := websocket.Message.Receive(sub.ws, &message)
		if err != nil {
			log.Println("Cannot read message from websocket")
			time.Sleep(100 * time.Millisecond)
			continue
		}
		log.Println("Received data:", message)
		sub.h(message)
	}
}
