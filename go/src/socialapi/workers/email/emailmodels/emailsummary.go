package emailmodels

import "fmt"

type EmailSummary struct {
	Title        string
	ChannelCount int
	MessageCount int
	Channels     []*ChannelSummary
}

// NewEmailSummary creates EmailSummary with given channelMap
func NewEmailSummary(channels []*ChannelSummary) *EmailSummary {
	messageCount := 0

	es := &EmailSummary{
		Channels:     channels,
		ChannelCount: len(channels),
	}
	es.Title = es.BuildTitle()

	for _, channelSummary := range channels {
		messageCount += channelSummary.UnreadCount
	}

	es.MessageCount = messageCount

	return es
}

func (es *EmailSummary) BuildTitle() string {
	messagePlural := ""
	channelInfo := ":"
	if es.MessageCount > 1 {
		messagePlural = "s"
	}

	if es.ChannelCount > 1 {
		channelInfo = fmt.Sprintf("in %d different channels:", es.ChannelCount)
	}

	return fmt.Sprintf("You have %d new message%s%s", es.MessageCount, messagePlural, channelInfo)
}

func (es *EmailSummary) Render() string {
	body := ""
	for _, cs := range es.Channels {
		body += cs.Render()
	}

	return body
}
