package tests

import (
	"fmt"
	"testing"

	"github.com/pubnub/go/messaging"
	"github.com/stretchr/testify/assert"
)

func TestGroupAddRemoveChannel(t *testing.T) {
	assert := assert.New(t)

	stop, sleep := NewVCRBoth(
		"fixtures/groups/addRemove", []string{})
	defer stop()

	group := "Group_AddRemove"
	channel1 := "Channel_AddRemove1"
	channel2 := "Channel_AddRemove2"
	channels := "Channel_AddRemove1,Channel_AddRemove2"

	successChannel := make(chan []byte)
	errorChannel := make(chan []byte)
	successListChannel := make(chan []byte)
	errorListChannel := make(chan []byte)

	uuid := "UUID_AddRemove_1"
	uuid2 := "UUID_AddRemove_2"
	pubnub := messaging.NewPubnub(PubKey, SubKey, SecKey, "", false, uuid, CreateLoggerForTests())

	go pubnub.ChannelGroupAddChannel(group, channels, successChannel, errorChannel)
	select {
	case response := <-successChannel:
		assert.Contains(string(response), "channel-registry")
		assert.Contains(string(response), "OK")
	case err := <-errorChannel:
		fmt.Println("Channel add error", string(err))
	case <-timeout():
		fmt.Println("Channel addtimeout")
	}

	sleep(1)

	go pubnub.ChannelGroupListChannels(group, successListChannel, errorListChannel)
	select {
	case response := <-successListChannel:
		assert.Contains(string(response), "payload")
		assert.Contains(string(response), "200")
		assert.Contains(string(response), channel1)
		assert.Contains(string(response), channel2)
	case err := <-errorListChannel:
		fmt.Println("Channel group list error", string(err))
	case <-timeout():
		fmt.Println("Channel group list timeout")
	}

	// Hack to versionize CGListChannels requests
	pubnub.SetUUID(uuid2)

	go pubnub.ChannelGroupRemoveChannel(group, channel1, successChannel, errorChannel)
	select {
	case response := <-successChannel:
		assert.Contains(string(response), "channel-registry")
		assert.Contains(string(response), "OK")
	case err := <-errorChannel:
		fmt.Println("Channel remove error", string(err))
	case <-timeout():
		fmt.Println("Channel remove timeout")
	}

	sleep(1)

	go pubnub.ChannelGroupListChannels(group, successListChannel, errorListChannel)
	select {
	case response := <-successListChannel:
		assert.Contains(string(response), "payload")
		assert.Contains(string(response), "200")
		assert.NotContains(string(response), channel1)
		assert.Contains(string(response), channel2)
	case err := <-errorListChannel:
		fmt.Println("Channel group list error", string(err))
	case <-timeout():
		fmt.Println("Channel group list timeout")
	}
}
