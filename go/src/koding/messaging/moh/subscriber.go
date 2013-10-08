package moh

import (
	"code.google.com/p/go.net/websocket"
	"log"
	"time"
)

type Subscriber struct {
	ws *websocket.Conn
	h  Handler
}

func NewSubscriber(addr string, h Handler) (*Subscriber, error) {
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
