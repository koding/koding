package messaging

import (
	"errors"
	"reflect"
	"strings"
)

type subscribeEnvelope struct {
	Messages      []subscribeMessage `json:"m"`
	TimetokenMeta timetokenMetadata  `json:"t"`
}

type timetokenMetadata struct {
	Timetoken string `json:"t"`
	Region    int    `json:"r"`
}

type subscribeMessage struct {
	Shard                    string            `json:"a"`
	SubscriptionMatch        string            `json:"b"`
	Channel                  string            `json:"c"`
	Payload                  interface{}       `json:"d"`
	Flags                    int               `json:"f"`
	IssuingClientId          string            `json:"i"`
	SubscribeKey             string            `json:"k"`
	SequenceNumber           uint64            `json:"s"`
	OriginatingTimetoken     timetokenMetadata `json:"o"`
	PublishTimetokenMetadata timetokenMetadata `json:"p"`
	UserMetadata             interface{}       `json:"u"`
	//WaypointList string `json:"w"`
	//EatAfterReading bool `json:"ear"`
	//ReplicationMap interface{} `json:"r"`
}

// PNMessageResult is a struct used to populate a message response for Subscribe v2
type PNMessageResult struct {
	ChannelGroup             string            `json:"ChannelGroup"`
	Channel                  string            `json:"Channel"`
	Payload                  interface{}       `json:"Payload"`
	IssuingClientId          string            `json:"IssuingClientId"`
	OriginatingTimetoken     timetokenMetadata `json:"OriginatingTimetoken"`
	PublishTimetokenMetadata timetokenMetadata `json:"PublishTimetokenMetadata"`
	UserMetadata             interface{}       `json:"UserMetadata"`
	//SubscribeKey             string            `json:"SubscribeKey"`
	//SequenceNumber           uint64            `json:"SequenceNumber"`
}

// PNPresenceEventResult is a struct used to populate a presence response for Subscribe v2
type PNPresenceEventResult struct {
	ChannelGroup         string            `json:"ChannelGroup"`
	Channel              string            `json:"Channel"`
	IssuingClientId      string            `json:"IssuingClientId"`
	OriginatingTimetoken timetokenMetadata `json:"OriginatingTimetoken"`
	UserMetadata         interface{}       `json:"UserMetadata"`
	Event                string            `json:"Event"`
	UUID                 string            `json:"UUID"`
	Timestamp            float64           `json:"Timestamp"`
	Occupancy            float64           `json:"Occupancy"`
	Join                 []interface{}     `json:"Join"`
	Timeout              []interface{}     `json:"Timeout"`
	Leave                []interface{}     `json:"Leave"`
	State                interface{}       `json:"State"`
}

// PNErrorData is a struct used to populate the error information, used in Subscribe v2
type PNErrorData struct {
	Information string `json:"Information"`
	Throwable   error  `json:"Throwable"`
}

// PNStatus is a struct used to populate status of the API call, used in Subscribe v2
type PNStatus struct {
	//StatusCode            int         `json:"StatusCode"`
	IsError               bool             `json:"Error"`
	ErrorData             PNErrorData      `json:"ErrorData"`
	AffectedChannels      []string         `json:"AffectedChannels"`
	AffectedChannelGroups []string         `json:"AffectedChannelGroups"`
	Category              PNStatusCategory `json:"PNStatusCategory"`
}

// PNStatusCategory conatins the enums for PNStatus
type PNStatusCategory int

// Enums for diff types of connections
const (
	PNUnknownCategory PNStatusCategory = 1 << iota
	PNAcknowledgmentCategory
	PNAccessDeniedCategory
	PNTimeoutCategory
	PNNetworkIssuesCategory
	PNConnectedCategory
	PNReconnectedCategory
	PNDisconnectedCategory
	PNUnexpectedDisconnectCategory
	PNCancelledCategory
	PNBadRequestCategory
	PNMalformedFilterExpressionCategory
	PNMalformedResponseCategory
	PNDecryptionErrorCategory
	PNTLSConnectionFailedCategory
	PNTLSUntrustedCertificateCategory
	PNRequestMessageCountExceededCategory
)

func createPNStatus(isError bool, message string, throwable error, category PNStatusCategory, AffectedChannels, AffectedChannelGroups []string) *PNStatus {
	status := &PNStatus{}
	if throwable != nil {
		status.ErrorData = PNErrorData{Information: message, Throwable: throwable}
	} else if isError && len(message) > 0 {
		err := errors.New(message)
		status.ErrorData = PNErrorData{Information: message, Throwable: err}
	}
	status.IsError = isError
	status.AffectedChannels = AffectedChannels
	status.AffectedChannelGroups = AffectedChannelGroups
	status.Category = category
	return status
}

func (msg *subscribeMessage) getMessageResponse() *PNMessageResult {
	res := &PNMessageResult{}
	res.Channel = msg.Channel
	res.IssuingClientId = msg.IssuingClientId
	res.OriginatingTimetoken = msg.OriginatingTimetoken
	res.Payload = msg.Payload
	res.PublishTimetokenMetadata = msg.PublishTimetokenMetadata
	//res.SequenceNumber = msg.SequenceNumber
	//res.SubscribeKey = msg.SubscribeKey
	res.ChannelGroup = msg.SubscriptionMatch
	res.UserMetadata = msg.UserMetadata
	return res
}

func (msg *subscribeMessage) getPresenceMessageResponse(pub *Pubnub) *PNPresenceEventResult {
	res := &PNPresenceEventResult{}
	res.Channel = strings.Replace(msg.Channel, presenceSuffix, "", -1)
	res.IssuingClientId = msg.IssuingClientId
	res.OriginatingTimetoken = msg.OriginatingTimetoken
	res.ChannelGroup = strings.Replace(msg.SubscriptionMatch, presenceSuffix, "", -1)
	res.UserMetadata = msg.UserMetadata

	payload, ok := msg.Payload.(map[string]interface{})
	if ok {
		pub.infoLogger.Printf("Info: converted to PresenceEvent %s", payload)
		if action, found := payload["action"]; found {
			res.Event = action.(string)
		}
		if uuid, found := payload["uuid"]; found {
			res.UUID = uuid.(string)
		}
		if occupancy, found := payload["occupancy"]; found {
			res.Occupancy = occupancy.(float64)
		}
		if timestamp, found := payload["timestamp"]; found {
			res.Timestamp = timestamp.(float64)
		}
		if data, found := payload["data"]; found {
			res.State = data
		}
		if data, found := payload["join"]; found {
			res.Join = data.([]interface{})
		}
		if data, found := payload["timeout"]; found {
			res.Timeout = data.([]interface{})
		}
		if data, found := payload["leave"]; found {
			res.Leave = data.([]interface{})
		}
		/*if joined, found := payload["joined"]; found {
			res.Joined = joined
		}
		if timedout, found := payload["timedout"]; found {
			res.Timedout = timedout
		}
		if hereNowRefresh, found := payload["here_now_refresh"]; found {
			res.HereNowRefresh = hereNowRefresh
		}*/
	} else {
		pub.infoLogger.Printf("ERROR: Not converted to PresenceEvent %f", msg.Payload)
		switch f := msg.Payload.(type) {
		case *PresenceEvent:
			pub.infoLogger.Printf("Info: PresenceEvent %s", f.Action)
		default:
			pub.infoLogger.Printf("Info: msg.Payload type %s, %s", reflect.TypeOf(msg.Payload), f)
		}
	}

	return res
}

func (env *subscribeEnvelope) getChannelsAndGroups(pub *Pubnub) (channels, channelGroups []string) {
	if env.Messages != nil {
		count := 0
		for _, msg := range env.Messages {
			count++
			msg.writeMessageLog(count, pub)
			channels = append(channels, msg.Channel)
			if (msg.Channel != msg.SubscriptionMatch) &&
				(!strings.Contains(msg.SubscriptionMatch, ".*")) &&
				(msg.SubscriptionMatch != "") {
				channelGroups = append(channelGroups, msg.SubscriptionMatch)
			}
		}
	}
	return channels, channelGroups
}

func (msg *subscribeMessage) writeMessageLog(count int, pub *Pubnub) {
	// start logging
	pub.infoLogger.Printf("INFO: -----Message %d-----", count)
	pub.infoLogger.Printf("INFO: Channel, %s", msg.Channel)
	pub.infoLogger.Printf("INFO: Flags, %d", msg.Flags)
	pub.infoLogger.Printf("INFO: IssuingClientId, %s", msg.IssuingClientId)
	pub.infoLogger.Printf("INFO: OriginatingTimetoken Region, %d", msg.OriginatingTimetoken.Region)
	pub.infoLogger.Printf("INFO: OriginatingTimetoken Timetoken, %s", msg.OriginatingTimetoken.Timetoken)
	pub.infoLogger.Printf("INFO: PublishTimetokenMetadata Region, %d", msg.PublishTimetokenMetadata.Region)
	pub.infoLogger.Printf("INFO: PublishTimetokenMetadata Timetoken, %s", msg.PublishTimetokenMetadata.Timetoken)

	strPayload, ok := msg.Payload.(string)
	if ok {
		pub.infoLogger.Printf("INFO: Payload, %s", strPayload)
	} else {
		pub.infoLogger.Printf("INFO: Payload, not converted to string %s", msg.Payload)
	}
	pub.infoLogger.Printf("INFO: SequenceNumber, %d", msg.SequenceNumber)
	pub.infoLogger.Printf("INFO: Shard, %s", msg.Shard)
	pub.infoLogger.Printf("INFO: SubscribeKey, %s", msg.SubscribeKey)
	pub.infoLogger.Printf("INFO: SubscriptionMatch, %s", msg.SubscriptionMatch)
	strUserMetadata, ok := msg.UserMetadata.(string)
	if ok {
		pub.infoLogger.Printf("INFO: UserMetadata, %s", strUserMetadata)
	} else {
		pub.infoLogger.Printf("INFO: UserMetadata, not converted to string")
	}
	// end logging
}
