package tests

import (
	"sync"
	"testing"

	"github.com/pubnub/go/messaging"
)

const (
	numGrants = 3
	ttl       = 3
	authKey   = "authKey"
	channel   = "channel"
)

func TestPubnubGrantSubscribeParallelUnsafe(t *testing.T) {
	wg := sync.WaitGroup{}
	pubnub := messaging.NewPubnub(PubKey, SubKey, SecKey, "", false, "", CreateLoggerForTests())

	for j := 0; j < numGrants; j++ {
		wg.Add(1)
		go func(j int) {
			defer wg.Done()
			callback, err := make(chan []byte), make(chan []byte)

			go pubnub.GrantSubscribe(channel, true, true, ttl, authKey, callback, err)
			select {
			case <-callback:
			case <-err:
			case <-messaging.SubscribeTimeout():
			}
		}(j)
	}
	wg.Wait()

}
