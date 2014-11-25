package emailmodels

import "fmt"

type EmailSummary struct {
	Title    string
	Channels []*ChannelSummary
}

// NewEmailSummary creates EmailSummary with given channelMap
func NewEmailSummary(channels []*ChannelSummary) *EmailSummary {
	es := &EmailSummary{
		Channels: channels,
	}
	es.Title = es.BuildTitle()

	return es
}

func (es *EmailSummary) BuildTitle() string {
	directMessageCount := 0
	groupMessageCount := 0
	groupChannelCount := 0
	for _, channel := range es.Channels {
		if len(channel.Participants) == 1 {
			directMessageCount += channel.UnreadCount
		} else {
			groupMessageCount += channel.UnreadCount
			groupChannelCount++
		}
	}

	title := "You have"

	if directMessageCount > 0 {
		title = fmt.Sprintf("%s %d direct message%s%s", title, directMessageCount, getPluralSuffix(directMessageCount), getConjunction(groupMessageCount))
	}

	if groupChannelCount > 0 {
		title = fmt.Sprintf("%s %d new message%s in %d group conversation%s", title, groupMessageCount, getPluralSuffix(groupMessageCount), groupChannelCount, getPluralSuffix(groupChannelCount))
	}

	return title + "."
}

func getPluralSuffix(count int) string {
	if count > 1 {
		return "s"
	}

	return ""
}

func getConjunction(count int) string {
	if count > 1 {
		return ", and there are"
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
