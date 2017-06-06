package main

import (
	"fmt"
	"time"

	"github.com/pubnub/go/messaging"
)

var pubnub *messaging.Pubnub

const (
	//PubKey
	PubKey string = "pub-c-56233908-f9d9-4a35-bd1f-e003bd75870c"
	//SubKey
	SubKey string = "sub-c-dec8da28-0617-11e6-996b-0619f8945a4f"
	//SecKey
	SecKey string = "sec-c-MzJkZGQ4MTYtMzNlMi00YzdmLTlkZmYtMWQ1NTczMDlhMTZi"
	//Channel
	Channel string = "blah"
)

const (
	workers    = 4
	multiplier = 10
)

func main() {
	// messaging.SetLogOutput(os.Stderr)
	pubnub = messaging.NewPubnub(PubKey, SubKey, SecKey, "", false, "", nil)
	messaging.SetNonSubscribeTimeout(2)

	send := make(chan string, 40)
	receive := make(chan string, 40)
	done := make(chan bool, 2)
	sync := make(chan bool)

	grant()

	go subscribeWorker(receive)
	go synchronizer(sync)

	for i := 0; i < workers; i++ {
		go worker(i, send, sync)
	}

	go func() {
		for j := 0; j < workers*multiplier; j++ {
			fmt.Printf(">>> %d: %s\n", j, <-send)
		}
		done <- true
	}()

	go func() {
		for k := 0; k < workers*multiplier; k++ {
			fmt.Printf("<<< %d: %s\n", k, <-receive)
		}
		done <- true
	}()

	<-done
	<-done
}

func synchronizer(sync chan<- bool) {
	for {
		sync <- true
		// Synchronized retention for publish requests
		time.Sleep(1 * time.Millisecond)
	}
}

func grant() {
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnub.GrantSubscribe(Channel, true, true, 0, "", successChannel, errorChannel)
	select {
	case <-successChannel:
	case err := <-errorChannel:
		panic(fmt.Sprintln("Error response", string(err)))
	case <-time.After(3 * time.Second):
		panic(fmt.Sprintln("Time request timeout"))
	}
}

func worker(startFrom int, ch chan<- string, sync <-chan bool) {
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	i := startFrom * multiplier

	for {
		i++
		<-sync
		go pubnub.Publish(Channel, fmt.Sprintf("hi/%d", i), successChannel, errorChannel)
		select {
		case msg := <-successChannel:
			ch <- string(msg)
		case err := <-errorChannel:
			ch <- fmt.Sprintln("Error response", string(err))
		case <-time.After(3 * time.Second):
			ch <- fmt.Sprintln("Time request timeout")
		}
	}
}

func subscribeWorker(ch chan<- string) {
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnub.Subscribe(Channel, "", successChannel, false, errorChannel)
	for {
		select {
		case msg := <-successChannel:
			ch <- string(msg)
		case err := <-errorChannel:
			ch <- fmt.Sprintln("Error response", string(err))
		case <-time.After(400 * time.Second):
			ch <- fmt.Sprintln("Time request timeout: 400")
		}
	}
}
