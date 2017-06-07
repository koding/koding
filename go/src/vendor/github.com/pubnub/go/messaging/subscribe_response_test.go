package messaging

import (
	"github.com/stretchr/testify/assert"
	//"log"
	//"os"
	"errors"
	"fmt"
	"strings"
	"testing"
)

func CreatePNStatusCommon(isChannelGroup bool, t *testing.T) {
	assert := assert.New(t)
	failedChannels := []string{"a"}
	failedChannels2 := []string{"b"}
	var affectedChannels, affectedChannelGroups []string
	groupText := ""
	if isChannelGroup {
		affectedChannelGroups = failedChannels
		groupText = " Group(s)"
	} else {
		affectedChannels = failedChannels2
		groupText = "(s)"
	}

	message := fmt.Sprintf("Invalid Channel%s: %s", groupText, "channel")

	status := createPNStatus(true, message, nil, 0, affectedChannels, affectedChannelGroups)

	assert.True(status.IsError)
	assert.Equal(status.ErrorData.Information, message)

	assert.Equal(status.ErrorData.Throwable, errors.New(message))
	assert.Equal(int(status.Category), 0)
	if isChannelGroup {
		assert.Equal(strings.Join(status.AffectedChannelGroups, ","), strings.Join(failedChannels, ","))
	} else {
		assert.Equal(strings.Join(status.AffectedChannels, ","), strings.Join(failedChannels2, ","))
	}
}

func TestCreatePNStatus(t *testing.T) {
	CreatePNStatusCommon(false, t)
}

func TestCreatePNStatusCG(t *testing.T) {
	CreatePNStatusCommon(true, t)
}

func TestGetMessageResponse(t *testing.T) {
	assert := assert.New(t)
	resp := `{"t":{"t":"14586613280736475","r":4},"m":[{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":1,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message"},{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":2,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message2"}]}`
	pubnub := NewPubnub("demo", "demo", "demo", "", true, "testuuid", CreateLoggerForTests())
	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(resp), "")
	response := subEnvelope.Messages[0].getMessageResponse()
	assert.Equal(response.Channel, "Channel_SubscriptionConnectedForSimple")
	assert.Equal(response.ChannelGroup, "Channel_SubscriptionConnectedForSimple")
	assert.Equal(response.Payload, "Test message")
	assert.Equal(response.PublishTimetokenMetadata.Timetoken, "14593254434932405")
	assert.Equal(response.IssuingClientId, "UUID_SubscriptionConnectedForSimple")
}

func TestGetPresenceMessageResponse(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "", true, "testuuid", CreateLoggerForTests())
	resp := `{"t":{"t":"14836953233974515","r":4},"m":[{"a":"2","f":0,"p":{"t":"14836953233242541","r":2},"k":"sub-c-f6e09df0-bd35-11e6-963b-0619f8945a4f","c":"test-pnpres","d":{"action": "join", "timestamp": 1483695323, "uuid": "bfce00ff4018fce180438bb04afc8da8", "occupancy": 1},"b":"test-pnpres"}]}`
	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(resp), "")
	response := subEnvelope.Messages[0].getPresenceMessageResponse(pubnub)
	assert.Equal(response.Channel, "test")
	assert.Equal(response.ChannelGroup, "test")
	assert.Equal(response.Event, "join")
	assert.Equal(response.UUID, "bfce00ff4018fce180438bb04afc8da8")
	assert.Equal(int(response.Timestamp), 1483695323)
	assert.Equal(response.Occupancy, float64(1))
}

func TestGetPresenceIntervalDeltasMessageResponse(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "", true, "testuuid", CreateLoggerForTests())
	resp := `{"t":{"t":"14907007978242728","r":4},"m":[{"a":"2","f":0,"p":{"t":"14907007977513457","r":2},"k":"sub-c-f6e09df0-bd35-11e6-963b-0619f8945a4f","c":"test-pnpres","d":{"action": "interval", "timestamp": 1490700797, "occupancy": 3, "join": ["Client-odx4y", "test"], "leave": ["left"], "timeout": ["timedout"]},"b":"test-pnpres"}]}`
	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(resp), "")
	response := subEnvelope.Messages[0].getPresenceMessageResponse(pubnub)
	assert.Equal(response.Channel, "test")
	assert.Equal(response.ChannelGroup, "test")
	assert.Equal(response.Event, "interval")
	assert.Equal(response.UUID, "")
	assert.Equal(int(response.Timestamp), 1490700797)
	assert.Equal(response.Join[0], "Client-odx4y")
	assert.Equal(response.Join[1], "test")
	assert.Equal(response.Leave[0], "left")
	assert.Equal(response.Timeout[0], "timedout")
	assert.Equal(response.Occupancy, float64(3))
}

func TestGetPresenceIntervalDeltasMessageResponseWithoutLeave(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "", true, "testuuid", CreateLoggerForTests())
	resp := `{"t":{"t":"14907007978242728","r":4},"m":[{"a":"2","f":0,"p":{"t":"14907007977513457","r":2},"k":"sub-c-f6e09df0-bd35-11e6-963b-0619f8945a4f","c":"test-pnpres","d":{"action": "interval", "timestamp": 1490700797, "occupancy": 3, "join": ["Client-odx4y", "test"], "timeout": ["timedout"]},"b":"test-pnpres"}]}`
	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(resp), "")
	response := subEnvelope.Messages[0].getPresenceMessageResponse(pubnub)
	assert.Equal(response.Channel, "test")
	assert.Equal(response.ChannelGroup, "test")
	assert.Equal(response.Event, "interval")
	assert.Equal(response.UUID, "")
	assert.Equal(int(response.Timestamp), 1490700797)
	assert.Equal(response.Join[0], "Client-odx4y")
	assert.Equal(response.Join[1], "test")
	assert.Equal(response.Timeout[0], "timedout")
	assert.Equal(response.Occupancy, float64(3))
}

func TestGetPresenceIntervalDeltasMessageResponseWithoutTimeout(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "", true, "testuuid", CreateLoggerForTests())
	resp := `{"t":{"t":"14907007978242728","r":4},"m":[{"a":"2","f":0,"p":{"t":"14907007977513457","r":2},"k":"sub-c-f6e09df0-bd35-11e6-963b-0619f8945a4f","c":"test-pnpres","d":{"action": "interval", "timestamp": 1490700797, "occupancy": 3, "join": ["Client-odx4y", "test"]},"b":"test-pnpres"}]}`
	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(resp), "")
	response := subEnvelope.Messages[0].getPresenceMessageResponse(pubnub)
	assert.Equal(response.Channel, "test")
	assert.Equal(response.ChannelGroup, "test")
	assert.Equal(response.Event, "interval")
	assert.Equal(response.UUID, "")
	assert.Equal(int(response.Timestamp), 1490700797)
	assert.Equal(response.Join[0], "Client-odx4y")
	assert.Equal(response.Join[1], "test")
	assert.Equal(response.Occupancy, float64(3))
}

func TestGetPresenceIntervalDeltasMessageResponseWithoutJoin(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "", true, "testuuid", CreateLoggerForTests())
	resp := `{"t":{"t":"14907007978242728","r":4},"m":[{"a":"2","f":0,"p":{"t":"14907007977513457","r":2},"k":"sub-c-f6e09df0-bd35-11e6-963b-0619f8945a4f","c":"test-pnpres","d":{"action": "interval", "timestamp": 1490700797, "occupancy": 3, "leave": ["Client-odx4y", "test"]},"b":"test-pnpres"}]}`
	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(resp), "")
	response := subEnvelope.Messages[0].getPresenceMessageResponse(pubnub)
	assert.Equal(response.Channel, "test")
	assert.Equal(response.ChannelGroup, "test")
	assert.Equal(response.Event, "interval")
	assert.Equal(response.UUID, "")
	assert.Equal(int(response.Timestamp), 1490700797)
	assert.Equal(response.Leave[0], "Client-odx4y")
	assert.Equal(response.Leave[1], "test")
	assert.Equal(response.Occupancy, float64(3))
}

func TestGetChannelsAndGroupsChannels(t *testing.T) {
	assert := assert.New(t)
	response := `{"t":{"t":"14586613280736475","r":4},"m":[{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":1,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message"},{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":2,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message2"}]}`
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.channels = *newSubscriptionEntity()
	pubnub.groups = *newSubscriptionEntity()
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)

	channel := "ch"
	channelGroup := "cg"
	pubnub.channels.Add(channel, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.groups.Add(channelGroup, callbackChannel, errorChannel, pubnub.infoLogger)

	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(response), "")
	channelNames, channelGroupNames := subEnvelope.getChannelsAndGroups(pubnub)

	strch := strings.Join(channelNames, ",")
	strcg := strings.Join(channelGroupNames, ",")

	//log.SetOutput(os.Stdout)
	//log.Printf("strch:%s", strch)
	//log.Printf("strcg:%s", strcg)
	assert.Equal("Channel_SubscriptionConnectedForSimple,Channel_SubscriptionConnectedForSimple", strch)
	assert.Equal("", strcg)
}

func TestGetChannelsAndGroupsChannelAndChannelGroup(t *testing.T) {
	assert := assert.New(t)
	response := `{"t":{"t":"14586613280736475","r":4},"m":[{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":2,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple_CG","d":"Test message2"}]}`
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.channels = *newSubscriptionEntity()
	pubnub.groups = *newSubscriptionEntity()
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)

	channel := "ch"
	channelGroup := "cg"
	pubnub.channels.Add(channel, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.groups.Add(channelGroup, callbackChannel, errorChannel, pubnub.infoLogger)

	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(response), "")
	channelNames, channelGroupNames := subEnvelope.getChannelsAndGroups(pubnub)

	strch := strings.Join(channelNames, ",")
	strcg := strings.Join(channelGroupNames, ",")

	//log.SetOutput(os.Stdout)
	//log.Printf("strch:%s", strch)
	//log.Printf("strcg:%s", strcg)
	assert.Equal("Channel_SubscriptionConnectedForSimple", strch)
	assert.Equal("Channel_SubscriptionConnectedForSimple_CG", strcg)
}

func TestGetChannelsAndGroupsWildcard(t *testing.T) {
	assert := assert.New(t)
	response := `{"t":{"t":"14586613280736475","r":4},"m":[{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":2,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple.*","d":"Test message2"}]}`
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.channels = *newSubscriptionEntity()
	pubnub.groups = *newSubscriptionEntity()
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)

	channel := "ch"
	channelGroup := "cg"
	pubnub.channels.Add(channel, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.groups.Add(channelGroup, callbackChannel, errorChannel, pubnub.infoLogger)

	subEnvelope, _, _, _ := pubnub.ParseSubscribeResponse([]byte(response), "")
	channelNames, channelGroupNames := subEnvelope.getChannelsAndGroups(pubnub)

	strch := strings.Join(channelNames, ",")
	strcg := strings.Join(channelGroupNames, ",")

	//log.SetOutput(os.Stdout)
	//log.Printf("strch:%s", strch)
	//log.Printf("strcg:%s", strcg)
	assert.Equal("Channel_SubscriptionConnectedForSimple", strch)
	assert.Equal("", strcg)
}
