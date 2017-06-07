package messaging

import (
	"fmt"
)

type responseType int
type errorType int

const (
	channelResponse responseType = 1 << iota
	channelGroupResponse
	wildcardResponse
)

type successResponse struct {
	Data      []byte
	Channel   string
	Source    string
	Timetoken string
	Presence  bool
	Type      responseType
}

func (r successResponse) Bytes() []byte {
	switch r.Type {
	case wildcardResponse:
		fallthrough
	case channelGroupResponse:
		return []byte(fmt.Sprintf(
			"[[%s], \"%s\", \"%s\", \"%s\"]", r.Data, r.Timetoken,
			removePnpres(r.Channel), removePnpres(r.Source)))
	case channelResponse:
		fallthrough
	default:
		return []byte(fmt.Sprintf(
			"[[%s], \"%s\", \"%s\"]", r.Data, r.Timetoken, removePnpres(r.Channel)))
	}
}

type errorResponse struct {
	Message         string
	DetailedMessage string
	Reason          responseStatus
	Type            responseType
}

func (e errorResponse) StringForSource(source string) string {
	// TODO: handle all reasons
	switch e.Reason {
	case responseAlreadySubscribed:
		fallthrough
	case responseNotSubscribed:
		if e.DetailedMessage != "" {
			return fmt.Sprintf("[0, \"%s %s '%s' %s\", %s, \"%s\"]",
				stringPresenceOrSubscribe(source),
				e.Type,
				source,
				e.Reason,
				e.DetailedMessage,
				source)
		}
		return fmt.Sprintf("[0, \"%s %s '%s' %s\", \"%s\"]",
			stringPresenceOrSubscribe(source),
			e.Type,
			source,
			e.Reason,
			source)
	case responseTimedOut:
		return fmt.Sprintf("[0, \"%s %s %s\", \"%s\"]",
			stringPresenceOrSubscribe(source),
			e.Type,
			e.Reason,
			source)
	case responseAsIsError:
		fallthrough
	default:
		return fmt.Sprintf("[0, \"%s\", \"%s\"]", e.Message, source)
	}
}

func (e errorResponse) BytesForSource(source string) []byte {
	return []byte(e.StringForSource(source))
}
