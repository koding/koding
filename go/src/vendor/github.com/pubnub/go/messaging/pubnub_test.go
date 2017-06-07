package messaging

import (
	"encoding/json"
	"fmt"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"log"
	//"os"
	"errors"
	"strings"
	"testing"
)

func TestReadPublishResponseAndCallSendResponseTooLong(t *testing.T) {
	value := []byte(`{"status":414,"service":"Balancer","error":true,"message":"Request URI Too Long"}`)
	err := errors.New("Test error")
	responseCode := 404

	ReadPublishResponseAndCallSendResponseCommon(t, value, responseCode, err)
}

func TestReadPublishResponseAndCallSendResponseSquareBrackets(t *testing.T) {
	value := []byte("[]")
	err := errors.New("Test error")
	responseCode := 404

	ReadPublishResponseAndCallSendResponseCommon(t, value, responseCode, err)
}

func TestReadPublishResponseAndCallSendResponseErrNil(t *testing.T) {
	value := []byte("[]")
	responseCode := 200

	ReadPublishResponseAndCallSendResponseCommon(t, value, responseCode, nil)
}

func TestReadPublishResponseAndCallSendResponseValueAndErrNil(t *testing.T) {
	responseCode := 400

	ReadPublishResponseAndCallSendResponseCommon(t, nil, responseCode, nil)
}

func TestReadPublishResponseAndCallSendResponseValueNil(t *testing.T) {
	responseCode := 400
	err := errors.New("Test error")
	ReadPublishResponseAndCallSendResponseCommon(t, nil, responseCode, err)
}

func TestReadPublishResponseAndCallSendResponseRespCodeZeroValueNotNull(t *testing.T) {
	responseCode := 400
	value := []byte(`[{"status":414,"service":"Balancer","error":true,"message":"Request URI Too Long"}]`)
	err := errors.New("Test error")
	ReadPublishResponseAndCallSendResponseCommon(t, value, responseCode, err)
}

func TestReadPublishResponseAndCallSendResponseValueNilRespCodeZero(t *testing.T) {
	responseCode := 0
	err := errors.New("Test error")
	ReadPublishResponseAndCallSendResponseCommon(t, nil, responseCode, err)
}

func TestReadPublishResponseAndCallSendResponseRespCodeZeroStringValue(t *testing.T) {
	responseCode := 400
	value := []byte(`["status"]`)
	err := errors.New("Test error")
	ReadPublishResponseAndCallSendResponseCommonWithResult(t, value, responseCode, err, "status")
}

func ReadPublishResponseAndCallSendResponseCommon(t *testing.T, value []byte, responseCode int, err error) {
	ReadPublishResponseAndCallSendResponseCommonWithResult(t, value, responseCode, err, "")
}

func ReadPublishResponseAndCallSendResponseCommonWithResult(t *testing.T, value []byte, responseCode int, err error, result string) {
	assert := assert.New(t)
	pubnub := NewPubnub("pam", "pam", "pam", "", true, "testuuid", CreateLoggerForTests())
	channel := "testChannel"
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)
	await := make(chan bool)
	//value := []byte("[]")

	go pubnub.readPublishResponseAndCallSendResponse(channel, value, responseCode, err, callbackChannel, errorChannel)

	go func() {
		for {
			select {
			case success, _ := <-callbackChannel:
				//fmt.Println(fmt.Sprintf("Response: %s ", success))
				assert.Contains(fmt.Sprintf("%s", success), string(value))
				await <- true
				break
			case failure, _ := <-errorChannel:
				//fmt.Println(fmt.Sprintf("Error Callback: %s", failure))

				assert.Contains(fmt.Sprintf("%s", failure), fmt.Sprintf("%d", responseCode))
				if len(result) > 0 {
					assert.Contains(fmt.Sprintf("%s", failure), string(result))
				} else {
					assert.Contains(fmt.Sprintf("%s", failure), string(value))
				}
				await <- true
				break
			}
		}
	}()

	<-await
}

func TestCheckSecretKeyAndAddSignatureWithSecretKey(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("pam", "pam", "pam", "", true, "testuuid", CreateLoggerForTests())
	opURL := "/publish/pam/pam/nrOHCskNQktfPYHhDGbeTNsLqmxoOBdBcI8fO221mIs=/test/0/%22test%22?pnsdk=PubNub-Go%2F3.11.0&uuid=pn-481813204005670480c7600f6ee6323c&seqn=1"
	requestURL := "/v1/channel-registration/sub-key/pam/channel-group/testcg11"
	response := pubnub.checkSecretKeyAndAddSignature(opURL, requestURL)
	assert.Contains(response, "/publish/pam/pam/nrOHCskNQktfPYHhDGbeTNsLqmxoOBdBcI8fO221mIs=/test/0/%22test%22?pnsdk=PubNub-Go%2F3.11.0&uuid=pn-481813204005670480c7600f6ee6323c&seqn=1")
	assert.Contains(response, "signature=")
	assert.Contains(response, "timestamp=")
}

func TestCheckSecretKeyAndAddSignatureWithoutSecretKey(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("pam", "pam", "", "", true, "testuuid", CreateLoggerForTests())
	opURL := "/publish/pam/pam/nrOHCskNQktfPYHhDGbeTNsLqmxoOBdBcI8fO221mIs=/test/0/%22test%22?pnsdk=PubNub-Go%2F3.11.0&uuid=pn-481813204005670480c7600f6ee6323c&seqn=1"
	requestURL := "/v1/channel-registration/sub-key/pam/channel-group/testcg11"
	response := pubnub.checkSecretKeyAndAddSignature(opURL, requestURL)
	assert.Contains(response, "/publish/pam/pam/nrOHCskNQktfPYHhDGbeTNsLqmxoOBdBcI8fO221mIs=/test/0/%22test%22?pnsdk=PubNub-Go%2F3.11.0&uuid=pn-481813204005670480c7600f6ee6323c&seqn=1")
	assert.NotContains(response, "signature=")
	assert.NotContains(response, "timetoken=")

}

func TestGenUuid(t *testing.T) {
	assert := assert.New(t)

	uuid, err := GenUuid()
	assert.Nil(err)
	assert.Len(uuid, 32)
}

func InvalidChannelCommon(ch string, isChannelGroup, expected bool, t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "", true, "testuuid", CreateLoggerForTests())
	b := pubnub.invalidChannelV2(ch, nil, isChannelGroup)
	assert.Equal(b, expected)
}

func TestInvalidChannelV2(t *testing.T) {
	InvalidChannelCommon("a, b", false, false, t)
}

func TestInvalidChannelGroupV2(t *testing.T) {
	InvalidChannelCommon("a,b", true, false, t)
}

func TestInvalidChannelFailV2(t *testing.T) {
	InvalidChannelCommon("a, ", false, true, t)
}

func TestInvalidChannelGroupFailV2(t *testing.T) {
	InvalidChannelCommon("", true, true, t)
}

func TestGetSubscribeLoopActionEmptyLists(t *testing.T) {
	assert := assert.New(t)
	pubnub := Pubnub{
		channels:   *newSubscriptionEntity(),
		groups:     *newSubscriptionEntity(),
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	errCh := make(chan []byte)

	action := pubnub.getSubscribeLoopAction("", "", errCh, nil)
	assert.Equal(subscribeLoopDoNothing, action)

	action = pubnub.getSubscribeLoopAction("channel", "", errCh, nil)
	assert.Equal(subscribeLoopStart, action)

	action = pubnub.getSubscribeLoopAction("", "group", errCh, nil)
	assert.Equal(subscribeLoopStart, action)
}

func TestConnectionEventChannel(t *testing.T) {
	name := "existing_channel1"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, false, false, false, t)
}
func TestConnectionEventChannelGroup(t *testing.T) {
	name := "existing_channelGroup1"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, true, false, false, t)
}
func TestConnectionEventChannelV2(t *testing.T) {
	name := "existing_channel2"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, false, true, false, t)
}
func TestConnectionEventChannelGroupV2(t *testing.T) {
	name := "existing_channelGroup2"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, true, true, false, t)
}

func TestConnectionEventChannelPres(t *testing.T) {
	name := "existing_channel1-pnpres"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, false, false, true, t)
}
func TestConnectionEventChannelGroupPres(t *testing.T) {
	name := "existing_channelGroup1-pnpres"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, true, false, true, t)
}
func TestConnectionEventChannelV2Pres(t *testing.T) {
	name := "existing_channel2-pnpres"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, false, true, true, t)
}
func TestConnectionEventChannelGroupV2Pres(t *testing.T) {
	name := "existing_channelGroup2-pnpres"
	sendConnectionEventToChannelOrChannelGroupsCommon(name, true, true, true, t)
}

func sendConnectionEventToChannelOrChannelGroupsCommon(name string, isChannelGroup, isV2, withPresence bool, t *testing.T) {

	pub := Pubnub{
		channels:   *newSubscriptionEntity(),
		groups:     *newSubscriptionEntity(),
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	var statusChannel = make(chan *PNStatus)
	var messageChannel = make(chan *PNMessageResult)
	var presenceChannel = make(chan *PNPresenceEventResult)

	existingSuccessChannel := make(chan []byte)
	existingErrorChannel := make(chan []byte)
	await := make(chan bool)
	if isV2 {
		sendConnectionEventToChannelOrChannelGroupsCommonV2(await, t, name, withPresence, isChannelGroup, statusChannel, messageChannel, presenceChannel)
		if isChannelGroup {

			pub.groups.AddV2(name, statusChannel, messageChannel, presenceChannel, pub.infoLogger)

			pub.sendConnectionEventToChannelOrChannelGroups(name, true, connectionConnected)

			pub.infoLogger.Printf("INFO: Awaiting: '%s', connected:", name)
		} else {

			pub.channels.AddV2(name, statusChannel, messageChannel, presenceChannel, pub.infoLogger)
			pub.sendConnectionEventToChannelOrChannelGroups(name, false, connectionConnected)
		}
		<-await
		pub.infoLogger.Printf("INFO: Awaited: '%s', connected:", name)

	} else {
		sendConnectionEventToChannelOrChannelGroupsCommonV1(await, t, name, withPresence, isChannelGroup, existingSuccessChannel, existingErrorChannel)
		if isChannelGroup {

			pub.groups.Add(name, existingSuccessChannel, existingErrorChannel, pub.infoLogger)
			pub.infoLogger.Printf("INFO: After add: '%s', connected:", name)
			pub.sendConnectionEventToChannelOrChannelGroups(name, true, connectionConnected)
		} else {
			pub.channels.Add(name, existingSuccessChannel, existingErrorChannel, pub.infoLogger)
			pub.infoLogger.Printf("INFO: after add '%s', connected:", name)
			pub.sendConnectionEventToChannelOrChannelGroups(name, false, connectionConnected)
		}
		pub.infoLogger.Printf("INFO: Awaiting: '%s', connected:", name)
		go func() {
			<-existingSuccessChannel
			<-existingErrorChannel

		}()

		<-await
		pub.infoLogger.Printf("INFO: Awaited: '%s', connected:", name)

	}

}

func sendConnectionEventToChannelOrChannelGroupsCommonV1(await chan bool, t *testing.T,
	name string, withPresence, isChannelGroup bool,
	existingSuccessChannel, existingErrorChannel <-chan []byte) {
	assert := assert.New(t)

	go func() {
		for {
			select {
			case success, ok := <-existingSuccessChannel:
				if !ok {
					break
				}
				res := string(success)
				if res != "[]" {

					//fmt.Println("RES:", res)
					assert.Contains(res, "connected")

					if withPresence {
						if strings.Contains(res, presenceSuffix) || (strings.Contains(res, "Presence")) {
							assert.True(true)
						}

					} else {
						assert.Contains(res, name)
					}

				}
				await <- true
				break
			case failure, ok := <-existingErrorChannel:
				if !ok {
					break
				}
				if string(failure) != "[]" {
					await <- true
				}
				break
			}
		}
	}()

}

func sendConnectionEventToChannelOrChannelGroupsCommonV2(await chan bool, t *testing.T,
	name string, withPresence, isChannelGroup bool,
	statusChannel chan *PNStatus,
	messageChannel chan *PNMessageResult,
	presenceChannel chan *PNPresenceEventResult) {
	assert := assert.New(t)
	go func() {
		for {
			select {
			case response := <-presenceChannel:
				if isChannelGroup {
					assert.Equal(response.ChannelGroup, name)
				} else {
					assert.Equal(response.Channel, name)
				}
			case response := <-messageChannel:
				if isChannelGroup {
					assert.Equal(response.ChannelGroup, name)
				} else {
					assert.Equal(response.Channel, name)
				}
			case err := <-statusChannel:
				//fmt.Println(err.AffectedChannelGroups)
				//fmt.Println(err.AffectedChannels)
				//fmt.Println(err.Category)
				if isChannelGroup {
					chs := strings.Join(err.AffectedChannelGroups, ",")
					assert.Contains(chs, name)
					if withPresence {
						assert.Contains(chs, presenceSuffix)
					}

				} else {
					chs := strings.Join(err.AffectedChannels, ",")
					assert.Contains(chs, name)
					if withPresence {
						assert.Contains(chs, presenceSuffix)
					}

				}
				assert.Equal(err.Category, PNConnectedCategory)

				//pub.infoLogger.Printf("INFO: Connected: '%s', connected: %s", name, strings.Join(err.AffectedChannelGroups, ","))
				await <- true
				break
			}
		}
	}()

}

func TestAddChannelsOrChannelGroups(t *testing.T) {
	assert := assert.New(t)
	pub := Pubnub{
		channels:   *newSubscriptionEntity(),
		groups:     *newSubscriptionEntity(),
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	var statusChannel = make(chan *PNStatus)
	var messageChannel = make(chan *PNMessageResult)
	var presenceChannel = make(chan *PNPresenceEventResult)
	channelOrChannelGroups := "ch1,ch2"
	pub.addChannelsOrChannelGroups(channelOrChannelGroups, false, "", statusChannel, messageChannel, presenceChannel)
	name := "ch1"
	item, found := pub.channels.Get(name)
	assert.Equal(item.Name, name)
	assert.Equal(found, true)
	assert.Equal(item.Connected, false)
	channelOrChannelGroups = "cg1,cg2"
	pub.addChannelsOrChannelGroups(channelOrChannelGroups, true, "", statusChannel, messageChannel, presenceChannel)
	name = "cg1"
	item, found = pub.groups.Get(name)
	assert.Equal(item.Name, name)
	assert.Equal(found, true)
	assert.Equal(item.Connected, false)
	channelOrChannelGroups = "cg3"
	pub.addChannelsOrChannelGroups(channelOrChannelGroups, true, "1231414515", statusChannel, messageChannel, presenceChannel)
	name = "cg3"
	item, found = pub.groups.Get(name)
	assert.Equal(item.Name, name)
	assert.Equal(found, true)
	assert.Equal(item.Connected, true)
	channelOrChannelGroups = "ch3"
	pub.addChannelsOrChannelGroups(channelOrChannelGroups, false, "1231414515", statusChannel, messageChannel, presenceChannel)
	name = "ch3"
	item, found = pub.channels.Get(name)
	assert.Equal(item.Name, name)
	assert.Equal(found, true)
	assert.Equal(item.Connected, true)
}

func TestAddPresenceChannels(t *testing.T) {
	assert := assert.New(t)
	channels := "ch1,ch2"
	channelGroups := "cg1,cg2"
	channels = addPresenceChannels(channels, true)
	channelGroups = addPresenceChannels(channelGroups, true)
	assert.Contains(channels, "ch1-pnpres")
	assert.Contains(channels, "ch2-pnpres")
	assert.Contains(channelGroups, "cg1-pnpres")
	assert.Contains(channelGroups, "cg2-pnpres")
	channels = "ch3,ch4"
	channelGroups = "cg3,cg4"

	channels = addPresenceChannels(channels, false)
	channelGroups = addPresenceChannels(channelGroups, false)
	assert.NotContains(channels, "ch3-pnpres")
	assert.NotContains(channels, "ch4-pnpres")
	assert.NotContains(channelGroups, "cg3-pnpres")
	assert.NotContains(channelGroups, "cg4-pnpres")

}

func TestCheckAlreadySubscribedChannelsOrChannelGroups(t *testing.T) {
	assert := assert.New(t)
	pub := Pubnub{
		channels:   *newSubscriptionEntity(),
		groups:     *newSubscriptionEntity(),
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	var statusChannel = make(chan *PNStatus)
	var messageChannel = make(chan *PNMessageResult)
	var presenceChannel = make(chan *PNPresenceEventResult)

	errorChannel := make(chan []byte)
	go func() {
		for {
			select {

			case _ = <-statusChannel:
				//fmt.Println(err.AffectedChannelGroups)
				//fmt.Println(err.AffectedChannels)
				//fmt.Println(err.Category)
				/*if isChannelGroup {
					chs := strings.Join(err.AffectedChannelGroups, ",")
					assert.Contains(chs, name)
					if withPresence {
						assert.Contains(chs, presenceSuffix)
					}

				} else {
					chs := strings.Join(err.AffectedChannels, ",")
					assert.Contains(chs, name)
					if withPresence {
						assert.Contains(chs, presenceSuffix)
					}

				}
				assert.Equal(err.Category, PNConnectedCategory)

				//pub.infoLogger.Printf("INFO: Connected: '%s', connected: %s", name, strings.Join(err.AffectedChannelGroups, ","))
				await <- true*/
				break
			}
		}
	}()

	go func() {
		for {
			select {

			case failure, ok := <-errorChannel:
				if !ok {
					break
				}
				if string(failure) != "[]" {
					//await <- true
				}
				break
			}
		}
	}()

	s := []string{"ch1"}
	s, i, b := pub.checkAlreadySubscribedChannelsOrChannelGroups(s, errorChannel, statusChannel, false)
	//fmt.Println("b1:", b)
	assert.True(b)
	pub.channels.AddV2("ch1", statusChannel, messageChannel, presenceChannel, pub.infoLogger)
	s = []string{"cg1"}
	_, _, b = pub.checkAlreadySubscribedChannelsOrChannelGroups(s, errorChannel, statusChannel, true)
	//fmt.Println("b2:", b)
	assert.True(b)
	pub.groups.AddV2("cg1", statusChannel, messageChannel, presenceChannel, pub.infoLogger)
	s = []string{"cg1"}
	_, _, b = pub.checkAlreadySubscribedChannelsOrChannelGroups(s, errorChannel, statusChannel, true)
	//fmt.Println("b3:", b)
	assert.False(b)
	s = []string{"ch1"}
	s, i, b = pub.checkAlreadySubscribedChannelsOrChannelGroups(s, errorChannel, statusChannel, false)
	//fmt.Println("b4:", b, s1, i)
	assert.False(b)

	s = []string{"cg2", "cg3"}
	s, i, b = pub.checkAlreadySubscribedChannelsOrChannelGroups(s, errorChannel, statusChannel, true)
	//fmt.Println("b5:", b, s1, i)
	assert.True(b)
	assert.Equal(i, 0)
	s = []string{"ch2", "ch3"}

	s, i, b = pub.checkAlreadySubscribedChannelsOrChannelGroups(s, errorChannel, statusChannel, false)
	//fmt.Println("b6:", b, s1, i)
	assert.True(b)
	assert.Equal(i, 0)
}

func TestGetSubscribeLoopActionListWithSingleChannel(t *testing.T) {
	assert := assert.New(t)
	pubnub := Pubnub{
		channels:   *newSubscriptionEntity(),
		groups:     *newSubscriptionEntity(),
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	existingSuccessChannel := make(chan []byte)
	existingErrorChannel := make(chan []byte)
	errCh := make(chan []byte)
	await := make(chan bool)

	pubnub.channels.Add("existing_channel",
		existingSuccessChannel, existingErrorChannel, pubnub.infoLogger)

	action := pubnub.getSubscribeLoopAction("", "", errCh, nil)
	assert.Equal(subscribeLoopDoNothing, action)

	action = pubnub.getSubscribeLoopAction("channel", "", errCh, nil)
	assert.Equal(subscribeLoopRestart, action)

	action = pubnub.getSubscribeLoopAction("", "group", errCh, nil)
	assert.Equal(subscribeLoopRestart, action)

	// existing
	go func() {
		<-errCh
		await <- true
	}()
	action = pubnub.getSubscribeLoopAction("existing_channel", "", errCh, nil)
	<-await
	assert.Equal(subscribeLoopDoNothing, action)
}

func TestGetSubscribeLoopActionListWithSingleGroup(t *testing.T) {
	assert := assert.New(t)
	pubnub := Pubnub{
		channels:   *newSubscriptionEntity(),
		groups:     *newSubscriptionEntity(),
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	existingSuccessChannel := make(chan []byte)
	existingErrorChannel := make(chan []byte)
	errCh := make(chan []byte)
	await := make(chan bool)

	pubnub.groups.Add("existing_group",
		existingSuccessChannel, existingErrorChannel, pubnub.infoLogger)

	action := pubnub.getSubscribeLoopAction("", "", errCh, nil)
	assert.Equal(subscribeLoopDoNothing, action)

	action = pubnub.getSubscribeLoopAction("channel", "", errCh, nil)
	assert.Equal(subscribeLoopRestart, action)

	action = pubnub.getSubscribeLoopAction("", "group", errCh, nil)
	assert.Equal(subscribeLoopRestart, action)

	// existing
	go func() {
		<-errCh
		await <- true
	}()
	action = pubnub.getSubscribeLoopAction("", "existing_group", errCh, nil)
	<-await
	assert.Equal(subscribeLoopDoNothing, action)
}

func TestGetSubscribeLoopActionListWithMultipleChannels(t *testing.T) {
	assert := assert.New(t)
	pubnub := Pubnub{
		channels:   *newSubscriptionEntity(),
		groups:     *newSubscriptionEntity(),
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	existingSuccessChannel := make(chan []byte)
	existingErrorChannel := make(chan []byte)
	errCh := make(chan []byte)
	await := make(chan bool)

	pubnub.channels.Add("ex_ch1",
		existingSuccessChannel, existingErrorChannel, pubnub.infoLogger)
	pubnub.channels.Add("ex_ch2",
		existingSuccessChannel, existingErrorChannel, pubnub.infoLogger)

	action := pubnub.getSubscribeLoopAction("ch1,ch2", "", errCh, nil)
	assert.Equal(subscribeLoopRestart, action)

	action = pubnub.getSubscribeLoopAction("", "gr1,gr2", errCh, nil)
	assert.Equal(subscribeLoopRestart, action)

	go func() {
		<-errCh
		await <- true
	}()
	action = pubnub.getSubscribeLoopAction("ch1,ex_ch1,ch2", "", errCh, nil)
	<-await
	assert.Equal(subscribeLoopRestart, action)

	go func() {
		<-errCh
		<-errCh
		await <- true
	}()
	action = pubnub.getSubscribeLoopAction("ex_ch1,ex_ch2", "", errCh, nil)
	<-await
	assert.Equal(subscribeLoopDoNothing, action)
}

var (
	testMessage1 = `PRISE EN MAIN - Le Figaro a pu approcher les nouveaux smartphones de Google. Voici nos premières observations. Le premier «smartphone conçu Google». Voilà comment a été présenté mardi le Pixel mardi. Il ne s'agit pas tout à fait de la première`
	testMessage2 = `Everybody copies everybody. It doesn't mean they're "out of ideas" or "in a technological cul-de-sac" - or at least it doesn't necessarily mean that - it does mean they want to make money and keep users.`
)

func BenchmarkEncodeNonASCIIChars(b *testing.B) {
	for i := 0; i < b.N; i++ {
		encodeNonASCIIChars(testMessage1)
		encodeNonASCIIChars(testMessage2)
	}
}

func TestEncodeNonASCIIChars(t *testing.T) {
	cases := []struct {
		input    string
		expected string
	}{
		{
			input:    testMessage1,
			expected: "PRISE EN MAIN - Le Figaro a pu approcher les nouveaux smartphones de Google. Voici nos premi\\u00e8res observations. Le premier \\u00absmartphone con\\u00e7u Google\\u00bb. Voil\\u00e0 comment a \\u00e9t\\u00e9 pr\\u00e9sent\\u00e9 mardi le Pixel mardi. Il ne s'agit pas tout \\u00e0 fait de la premi\\u00e8re",
		},
		{
			input:    testMessage2,
			expected: testMessage2, // no non-ascii characters here, so the string should be unchanged
		},
		{
			input:    "",
			expected: "",
		},
	}
	for _, tc := range cases {
		assert.Equal(t, encodeNonASCIIChars(tc.input), tc.expected)
	}
}

func TestFilterExpression(t *testing.T) {
	assert := assert.New(t)
	pubnub := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	var filterExp = "aoi_x >= 0 AND aoi_x <= 2 AND aoi_y >= 0 AND aoi_y<= 2"
	pubnub.SetFilterExpression(filterExp)
	assert.Equal(pubnub.FilterExpression(), filterExp)
}

func TestCheckCallbackNilException(t *testing.T) {
	assert := assert.New(t)
	// Handle errors in defer func with recover.
	defer func() {
		if r := recover(); r != nil {
			var ok bool
			err, ok := r.(error)
			if !ok {
				err = fmt.Errorf("pkg: %v", r)
				//fmt.Println(err)
				assert.True(strings.Contains(err.Error(), "Callback is nil for GrantSubscribe"))
			}
		}

	}()

	pubnub := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	var callbackChannel = make(chan []byte)
	close(callbackChannel)
	callbackChannel = nil
	pubnub.checkCallbackNil(callbackChannel, false, "GrantSubscribe")

}

func TestCheckCallbackNil(t *testing.T) {
	assert := assert.New(t)
	// Handle errors in defer func with recover.
	defer func() {
		if r := recover(); r != nil {
			var ok bool
			err, ok := r.(error)
			if !ok {
				err = fmt.Errorf("pkg: %v", r)
				//fmt.Println(err)
				assert.True(strings.Contains(err.Error(), "Callback is nil for GrantSubscribe"))
			} else {
				assert.True(true)
			}
		}

	}()
	pubnub := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	var callbackChannel = make(chan []byte)
	pubnub.checkCallbackNil(callbackChannel, false, "GrantSubscribe")

}

func TestCheckCallbackNilV2(t *testing.T) {
	assert := assert.New(t)
	// Handle errors in defer func with recover.
	defer func() {
		if r := recover(); r != nil {
			var ok bool
			err, ok := r.(error)
			if !ok {
				err = fmt.Errorf("pkg: %v", r)
				//fmt.Println(err)
				assert.True(strings.Contains(err.Error(), "Callback is nil for GrantSubscribe"))
			} else {
				assert.True(true)
			}
		}

	}()
	pubnub := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	var statusChannel = make(chan *PNStatus)
	var messageChannel = make(chan *PNMessageResult)
	var presenceChannel = make(chan *PNPresenceEventResult)

	pubnub.checkCallbackNilV2(statusChannel, messageChannel, presenceChannel, "GrantSubscribe", false)
}

func TestCheckCallbackNilV2Exception(t *testing.T) {
	assert := assert.New(t)
	// Handle errors in defer func with recover.
	defer func() {
		if r := recover(); r != nil {
			var ok bool
			err, ok := r.(error)
			if !ok {
				err = fmt.Errorf("pkg: %v", r)
				//fmt.Println(err)
				assert.True(strings.Contains(err.Error(), " Callback is nil for function GrantSubscribe"))
			}
		}

	}()
	pubnub := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	var messageChannel = make(chan *PNMessageResult)
	var presenceChannel = make(chan *PNPresenceEventResult)

	pubnub.checkCallbackNilV2(nil, messageChannel, presenceChannel, "GrantSubscribe", false)
}

func TestExtractMessage(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := `{"t":{"t":"14586613280736475","r":4},"m":[{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":1,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message"},{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":2,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message2"}]}`

	subEnvelope, newTimetoken, region, _ := pubnub.ParseSubscribeResponse([]byte(response), "")
	count := 0
	if subEnvelope.Messages != nil {
		for _, msg := range subEnvelope.Messages {
			count++
			var message = pubnub.extractMessage(msg)
			var msgStr = string(message)
			if count == 1 {
				assert.Equal("\"Test message\"", msgStr)
			} else {
				assert.Equal("\"Test message2\"", msgStr)
			}
		}
	}
	assert.Equal(newTimetoken, "14586613280736475")
	assert.Equal("4", region)
	assert.Equal(2, count)

}

func TestExtractMessageCipherNonEncryptedMessage(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := `{"t":{"t":"14586613280736475","r":4},"m":[{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":1,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message"},{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":2,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"Test message2"}]}`

	subEnvelope, newTimetoken, region, _ := pubnub.ParseSubscribeResponse([]byte(response), "")
	count := 0
	if subEnvelope.Messages != nil {
		for _, msg := range subEnvelope.Messages {
			count++
			var message = pubnub.extractMessage(msg)
			var msgStr = string(message)
			if count == 1 {
				assert.Equal("\"Test message\"", msgStr)
			} else {
				assert.Equal("\"Test message2\"", msgStr)
			}
		}
	}
	assert.Equal(newTimetoken, "14586613280736475")
	assert.Equal("4", region)
	assert.Equal(2, count)

}

func TestExtractMessageCipher(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := `{"t":{"t":"14586613280736475","r":4},"m":[{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":1,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"HSoHp4g0o/uHfiS1PYXzWw=="},{"a":"1","f":0,"i":"UUID_SubscriptionConnectedForSimple","s":2,"p":{"t":"14593254434932405","r":4},"k":"sub-c-5c4fdcc6-c040-11e5-a316-0619f8945a4f","c":"Channel_SubscriptionConnectedForSimple","b":"Channel_SubscriptionConnectedForSimple","d":"xXch1+uwbgGgLOudCKzFSw=="}]}`

	subEnvelope, newTimetoken, region, _ := pubnub.ParseSubscribeResponse([]byte(response), "")
	count := 0
	if subEnvelope.Messages != nil {
		for _, msg := range subEnvelope.Messages {
			count++
			var message = pubnub.extractMessage(msg)
			var msgStr = string(message)
			if count == 1 {
				assert.Equal("\"Test message\"", msgStr)
			} else {
				assert.Equal("\"message2\"", msgStr)
			}
		}
	}
	assert.Equal(newTimetoken, "14586613280736475")
	assert.Equal("4", region)
	assert.Equal(2, count)

}

func TestGetDataCipher(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := `[["h5Uhyc8uf3h11w5C68QsVenCf7Llvdq5XWLa1RSgdfU=","AA9MBpymUzq/bfLCtIKFB+J6L+s3UGm6xPGh9kuXsoQ=","SfGYYp58jU2FGBNNsRk0kZ8KWRjZ6OsG3OxSySd7FF0=","ek+lrKjHCJPp5wYpxWlZcg806w/SWU5dzNYmjqDVb6o=","HrIrwvdGrm3/TM4kCf0EGl5SzcD+JqOXesWtzzc8+UA="],14610686757083461,14610686757935083]`
	var contents = []byte(response)
	var s interface{}
	err := json.Unmarshal(contents, &s)
	if err == nil {
		v := s.(interface{})
		switch vv := v.(type) {
		case []interface{}:
			length := len(vv)
			if length > 0 {
				msgStr := pubnub.getData(vv[0], pubnub.cipherKey)
				//pubnub.infoLogger.Printf(msgStr)
				assert.Equal("[\"Test Message 5\",\"Test Message 6\",\"Test Message 7\",\"Test Message 8\",\"Test Message 9\"]", msgStr)
			}
		default:
			assert.Fail("default fall through")
		}
	} else {
		assert.Fail("Unmarshal failed")
	}
}

func TestGetData(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		//cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := "[[\"Test Message 5\",\"Test Message 6\",\"Test Message 7\",\"Test Message 8\",\"Test Message 9\"],14610686757083461,14610686757935083]"
	var contents = []byte(response)
	var s interface{}
	err := json.Unmarshal(contents, &s)
	if err == nil {
		v := s.(interface{})
		switch vv := v.(type) {
		case []interface{}:
			length := len(vv)
			if length > 0 {
				msgStr := pubnub.getData(vv[0], pubnub.cipherKey)
				//pubnub.infoLogger.Printf(msgStr)
				assert.Equal("[\"Test Message 5\",\"Test Message 6\",\"Test Message 7\",\"Test Message 8\",\"Test Message 9\"]", msgStr)
			}
		default:
			assert.Fail("default fall through")
		}
	} else {
		assert.Fail("Unmarshal failed %s", err.Error())
	}
}

func TestGetDataCipherNonEnc(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := "[[\"Test Message 5\",\"Test Message 6\",\"Test Message 7\",\"Test Message 8\",\"Test Message 9\"],14610686757083461,14610686757935083]"
	var contents = []byte(response)
	var s interface{}
	err := json.Unmarshal(contents, &s)
	if err == nil {
		v := s.(interface{})
		switch vv := v.(type) {
		case []interface{}:
			length := len(vv)
			if length > 0 {
				msgStr := pubnub.getData(vv[0], pubnub.cipherKey)
				//pubnub.infoLogger.Printf(msgStr)
				assert.Equal("[\"Test Message 5\",\"Test Message 6\",\"Test Message 7\",\"Test Message 8\",\"Test Message 9\"]", msgStr)
			}
		default:
			assert.Fail("default fall through")
		}
	} else {
		assert.Fail("Unmarshal failed %s", err.Error())
	}
}

func TestGetDataCipherSingle(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := `["h5Uhyc8uf3h11w5C68QsVenCf7Llvdq5XWLa1RSgdfU=",9223372036854775808346,10223372036854775808084]`
	var contents = []byte(response)
	var s interface{}
	err := json.Unmarshal(contents, &s)
	if err == nil {
		v := s.(interface{})
		switch vv := v.(type) {
		case []interface{}:
			length := len(vv)
			if length > 0 {
				msgStr := pubnub.parseInterface(vv, pubnub.cipherKey)
				//pubnub.infoLogger.Printf(msgStr)
				assert.Equal("[\"Test Message 5\",9.223372036854776e+21,1.0223372036854776e+22]", msgStr)
			}
		default:
			assert.Fail("default fall through")
		}
	} else {
		assert.Fail("Unmarshal failed")
	}
}

func TestGetDataSingle(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		//cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := "[\"Test Message 5\",9223372036854775808346,10223372036854775808084]"
	var contents = []byte(response)
	var s interface{}
	err := json.Unmarshal(contents, &s)
	if err == nil {
		v := s.(interface{})
		switch vv := v.(type) {
		case []interface{}:
			msgStr := pubnub.parseInterface(vv, pubnub.cipherKey)
			assert.Equal("[\"Test Message 5\",9.223372036854776e+21,1.0223372036854776e+22]", msgStr)
		default:
			assert.Fail("default fall through")
		}
	} else {
		assert.Fail("Unmarshal failed %s", err.Error())
	}
}

func TestGetDataCipherNonEncSingle(t *testing.T) {
	assert := assert.New(t)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}
	response := "[\"Test Message 5\",9223372036854775808346,10223372036854775808084]"
	var contents = []byte(response)
	var s interface{}
	err := json.Unmarshal(contents, &s)
	if err == nil {
		v := s.(interface{})
		switch vv := v.(type) {
		case []interface{}:
			length := len(vv)
			if length > 0 {
				msgStr := pubnub.parseInterface(vv, pubnub.cipherKey)
				//pubnub.infoLogger.Printf(msgStr)
				assert.Equal("[\"Test Message 5\",9.223372036854776e+21,1.0223372036854776e+22]", msgStr)
			}
		default:
			assert.Fail("default fall through")
		}
	} else {
		assert.Fail("Unmarshal failed %s", err.Error())
	}
}

func TestInvalidChannel(t *testing.T) {
	assert := assert.New(t)
	var errorChannel = make(chan []byte)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	go func() {
		for {
			select {

			case _, ok := <-errorChannel:
				if !ok {
					break
				}
				return
			}
		}

	}()
	b := pubnub.invalidChannel(" ,", errorChannel)
	assert.True(b)
}

func TestInvalidChannelNeg(t *testing.T) {
	assert := assert.New(t)
	var errorChannel = make(chan []byte)

	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	go func() {
		for {
			select {

			case _, ok := <-errorChannel:
				if !ok {
					break
				}
				return
			}
		}

	}()
	b := pubnub.invalidChannel("\"a\"", errorChannel)
	assert.True(!b)
}

func TestInvalidMessage(t *testing.T) {
	assert := assert.New(t)
	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	response := "[\"Test Message 5\",14610686757083461,14610686757935083]"
	var contents = []byte(response)
	var s interface{}
	err := json.Unmarshal(contents, &s)
	if err != nil {
		assert.Fail("json unmashal error", err.Error())
	}
	b := pubnub.invalidMessage(s)
	assert.True(!b)
}

func TestInvalidMessageFail(t *testing.T) {
	assert := assert.New(t)
	pubnub := Pubnub{
		cipherKey:  "enigma",
		infoLogger: log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	var s interface{}
	json.Unmarshal(nil, &s)

	b := pubnub.invalidMessage(s)
	assert.True(b)
}

func TestCreateSubscribeURLReset(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.channels = *newSubscriptionEntity()
	pubnub.groups = *newSubscriptionEntity()
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)

	channel := "ch"
	channelGroup := "cg"
	pubnub.channels.Add(channel, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.groups.Add(channelGroup, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.resetTimeToken = true
	pubnub.SetFilterExpression("aoi_x >= 0")
	pubnub.userState = make(map[string]map[string]interface{})
	presenceHeartbeat = 10
	jsonString := "{\"k\":\"v\"}"
	var s interface{}
	json.Unmarshal([]byte(jsonString), &s)

	pubnub.userState[channel] = s.(map[string]interface{})

	senttt := "0"
	b, tt := pubnub.createSubscribeURL("", "4")
	//log.SetOutput(os.Stdout)
	//log.Printf("b:%s, tt:%s", b, tt)
	assert.Contains(b, "/v2/subscribe/demo/ch/0?channel-group=cg&uuid=testuuid&tt=0&tr=4&filter-expr=aoi_x%20%3E%3D%200&heartbeat=10&state=%7B%22ch%22%3A%7B%22k%22%3A%22v%22%7D%7D&pnsdk=PubNub-Go%2F3.14.0")
	assert.Equal(senttt, tt)
	presenceHeartbeat = 0
}

func TestCreateSubscribeURL(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.channels = *newSubscriptionEntity()
	pubnub.groups = *newSubscriptionEntity()
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)

	channel := "ch"
	channelGroup := "cg"
	pubnub.channels.Add(channel, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.groups.Add(channelGroup, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.resetTimeToken = false
	pubnub.SetFilterExpression("aoi_x >= 0")

	senttt := "14767805072942467"
	pubnub.timeToken = senttt
	b, tt := pubnub.createSubscribeURL("14767805072942467", "4")
	//log.SetOutput(os.Stdout)
	//log.Printf("b:%s, tt:%s", b, tt)
	assert.Contains(b, "/v2/subscribe/demo/ch/0?channel-group=cg&uuid=testuuid&tt=14767805072942467&tr=4&filter-expr=aoi_x%20%3E%3D%200&pnsdk=PubNub-Go%2F3.14.0")
	assert.Equal(senttt, tt)
}

func TestCreateSubscribeURLFilterExp(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.channels = *newSubscriptionEntity()
	pubnub.groups = *newSubscriptionEntity()
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)

	channel := "ch"
	channelGroup := "cg"
	pubnub.channels.Add(channel, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.groups.Add(channelGroup, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.resetTimeToken = false
	pubnub.SetFilterExpression("aoi_x >= 0 AND aoi_x <= 2 AND aoi_y >= 0 AND aoi_y<= 2")

	senttt := "14767805072942467"
	pubnub.timeToken = senttt
	b, tt := pubnub.createSubscribeURL("14767805072942467", "4")
	//log.SetOutput(os.Stdout)
	//log.Printf("b:%s, tt:%s", b, tt)
	assert.Contains(b, "/v2/subscribe/demo/ch/0?channel-group=cg&uuid=testuuid&tt=14767805072942467&tr=4&filter-expr=aoi_x%20%3E%3D%200%20AND%20aoi_x%20%3C%3D%202%20AND%20aoi_y%20%3E%3D%200%20AND%20aoi_y%3C%3D%202&pnsdk=PubNub-Go%2F3.14.0")
	assert.Equal(senttt, tt)
}

func TestCreatePresenceHeartbeatURL(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.channels = *newSubscriptionEntity()
	pubnub.groups = *newSubscriptionEntity()
	var callbackChannel = make(chan []byte)
	var errorChannel = make(chan []byte)

	channel := "ch"
	channelGroup := "cg"
	pubnub.channels.Add(channel, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.groups.Add(channelGroup, callbackChannel, errorChannel, pubnub.infoLogger)
	pubnub.resetTimeToken = true
	pubnub.SetFilterExpression("aoi_x >= 0")
	pubnub.userState = make(map[string]map[string]interface{})
	presenceHeartbeat = 10
	jsonString := "{\"k\":\"v\"}"
	var s interface{}
	json.Unmarshal([]byte(jsonString), &s)

	pubnub.userState[channel] = s.(map[string]interface{})

	b := pubnub.createPresenceHeartbeatURL()
	//log.SetOutput(os.Stdout)
	//log.Printf("b:%s", b)

	assert.Equal("/v2/presence/sub_key/demo/channel/ch/heartbeat?channel-group=cg&uuid=testuuid&heartbeat=10&state=%7B%22ch%22%3A%7B%22k%22%3A%22v%22%7D%7D&pnsdk=PubNub-Go%2F3.14.0", b)
	presenceHeartbeat = 0

}

func TestAddAuthParam(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.SetAuthenticationKey("authKey")
	b := pubnub.addAuthParam(true)

	assert.Equal("&auth=authKey", b)
}

func TestAddAuthParamQSTrue(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	pubnub.SetAuthenticationKey("authKey")
	b := pubnub.addAuthParam(false)

	assert.Equal("?auth=authKey", b)
}

func TestAddAuthParamEmpty(t *testing.T) {
	assert := assert.New(t)
	pubnub := NewPubnub("demo", "demo", "demo", "enigma", true, "testuuid", CreateLoggerForTests())
	b := pubnub.addAuthParam(false)

	assert.Equal("", b)
}

func TestCheckQuerystringInit(t *testing.T) {
	assert := assert.New(t)
	b := checkQuerystringInit(false)

	assert.Equal("?", b)
}

func TestCheckQuerystringInitFalse(t *testing.T) {
	assert := assert.New(t)
	b := checkQuerystringInit(true)

	assert.Equal("&", b)
}
