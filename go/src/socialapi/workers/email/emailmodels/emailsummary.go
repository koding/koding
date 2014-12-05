package emailmodels

type EmailSummary struct {
	Channels []*ChannelSummary
}

// NewEmailSummary creates EmailSummary with given channelMap
func NewEmailSummary(css ...*ChannelSummary) *EmailSummary {
	es := &EmailSummary{
		Channels: css,
	}

	return es
}

func getPluralSuffix(count int) string {
	if count > 1 {
		return "s"
	}

	return ""
}

func (es *EmailSummary) Render() (string, error) {
	body := ""
	for _, cs := range es.Channels {
		content, err := cs.Render()
		if err != nil {
			return "", err
		}
		body += content
	}

	return body, nil
}
