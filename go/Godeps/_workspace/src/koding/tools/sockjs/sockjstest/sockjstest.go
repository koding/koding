package main

import (
	"fmt"
	"koding/tools/sockjs"
	"net/http"
	"time"
)

func main() {
	mux := &sockjs.Mux{
		Services: map[string]*sockjs.Service{
			"/echo": sockjs.NewService("http://localhost/sockjs.js", true, false, 2*time.Second, 4096, func(receiveChan <-chan interface{}, sendChan chan<- interface{}) {
				for message := range receiveChan {
					sendChan <- message
				}
			}),
			"/disabled_websocket_echo": sockjs.NewService("http://localhost/sockjs.js", false, false, 2*time.Second, 0, func(receiveChan <-chan interface{}, sendChan chan<- interface{}) {
				for message := range receiveChan {
					sendChan <- message
				}
			}),
			"/cookie_needed_echo": sockjs.NewService("http://localhost/sockjs.js", true, true, 2*time.Second, 0, func(receiveChan <-chan interface{}, sendChan chan<- interface{}) {
				for message := range receiveChan {
					sendChan <- message
				}
			}),
			"/close": sockjs.NewService("http://localhost/sockjs.js", true, false, 2*time.Second, 0, func(receiveChan <-chan interface{}, sendChan chan<- interface{}) {
				// do nothing, will close immediately
			}),
		},
	}

	s := &http.Server{
		Addr:    ":8081",
		Handler: mux,
	}
	fmt.Println("Ready...")
	err := s.ListenAndServe()
	if err != nil {
		fmt.Println(err)
	}
}
