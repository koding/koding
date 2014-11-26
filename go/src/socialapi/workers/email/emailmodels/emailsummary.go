package emailmodels

import "fmt"

type EmailSummary struct {
	Title    string
	Channels []*ChannelSummary
}

// NewEmailSummary creates EmailSummary with given channelMap
func NewEmailSummary(css ...*ChannelSummary) *EmailSummary {
	es := &EmailSummary{
		Channels: css,
	}

	return es
}

func (es *EmailSummary) BuildPrivateMessageTitle() {
	messagePreviewCount := 0
	unreadMessageCount := 0
	for _, channel := range es.Channels {
		unreadMessageCount += channel.UnreadCount
		messagePreviewCount += len(channel.MessageSummaries)
	}

	title := "You have a few unread messages on Koding.com."

	title = fmt.Sprintf("%s Here are the latest %d.", title, messagePreviewCount)

	if unreadMessageCount > messagePreviewCount {
		title = fmt.Sprintf("%s You also have %d more.", title, unreadMessageCount-messagePreviewCount)
	}

	es.Title = title
}

func getPluralSuffix(count int) string {
	if count > 1 {
		return "s"
	}

	return ""
}

func (es *EmailSummary) Render() (string, error) {
	body := es.Title
	for _, cs := range es.Channels {
		content, err := cs.Render()
		if err != nil {
			return "", err
		}
		body += content
	}

	return body, nil
}
