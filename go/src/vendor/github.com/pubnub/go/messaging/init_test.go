package messaging

import (
	"fmt"
	"io/ioutil"
	"log"
	"regexp"
	"time"
)

func init() {
	//initLogging()
}

var pubnub = Pubnub{
	subscribeKey: "demo",
}

var (
	channelsSingleChannel    = *newSubscriptionEntity()
	channelsThreeChannels    = *newSubscriptionEntity()
	channelsSingleCG         = *newSubscriptionEntity()
	channelsThreeCG          = *newSubscriptionEntity()
	channelsChannelAndGroupC = *newSubscriptionEntity()
	channelsChannelAndGroupG = *newSubscriptionEntity()

	pubnubSingleChannel = Pubnub{
		channels:     channelsSingleChannel,
		subscribeKey: "my_key",
		uuid:         "my_uuid",
		infoLogger:   log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	pubnubThreeChannels = Pubnub{
		channels:     channelsThreeChannels,
		subscribeKey: "my_key",
		uuid:         "my_uuid",
		infoLogger:   log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	pubnubSingleCG = Pubnub{
		groups:       channelsSingleCG,
		subscribeKey: "my_key",
		uuid:         "my_uuid",
		infoLogger:   log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	pubnubThreeCG = Pubnub{
		groups:       channelsThreeCG,
		subscribeKey: "my_key",
		uuid:         "my_uuid",
		infoLogger:   log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	pubnubChannelAndGroup = Pubnub{
		channels:     channelsChannelAndGroupC,
		groups:       channelsChannelAndGroupG,
		subscribeKey: "my_key",
		uuid:         "my_uuid",
		infoLogger:   log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile),
	}

	successChannel = make(chan []byte)
	errorChannel   = make(chan []byte)
)

var signatureRegexp, _ = regexp.Compile("&signature=.*$")

func timestamp() string {
	return fmt.Sprintf("%d", time.Now().Unix())
}

func truncateSignature(input string) (output string) {
	return signatureRegexp.ReplaceAllString(input, "")
}
