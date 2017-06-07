package main

import (
	"flag"
	"fmt"
	"github.com/pubnub/go/messaging"
)

func main() {
	publishKey := flag.String("pub", "demo", "publish key")
	subscribeKey := flag.String("sub", "demo", "subscribe key")
	secretKey := flag.String("secret", "demo", "secret key")

	channels := flag.String("channels", "qwer,qwer-pnpres", "channels to subscribe to")
	groups := flag.String("groups", "zzz,zzz-pnpres", "channel groups to subscribe to")

	pubnub := messaging.NewPubnub(*publishKey, *subscribeKey, *secretKey, "", false, "", nil)

	go populateGroup(pubnub, "zzz", "asdf")

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	go pubnub.Subscribe(*channels, "", successChannel, false, errorChannel)
	go pubnub.ChannelGroupSubscribe(*groups, successChannel, errorChannel)

	subscribeHandler(successChannel, errorChannel)
}

func subscribeHandler(successChannel, errorChannel chan []byte) {

	for {
		select {
		case response := <-successChannel:
			fmt.Printf("Success response: %s", response)
		case err := <-errorChannel:
			fmt.Printf("Error response: %s", err)
		case <-messaging.SubscribeTimeout():
			fmt.Printf("Subscirbe request timeout")
		}
	}
}

func populateGroup(pubnub *messaging.Pubnub, group, channels string) {
	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)

	pubnub.ChannelGroupAddChannel(group, channels, successChannel, errorChannel)

	select {
	case <-successChannel:
	case <-errorChannel:
	}
}
