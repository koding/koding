package emailmodels

import (
	"bytes"
	"socialapi/config"
	"socialapi/workers/email/templates"
	"text/template"
)

// MessageSummary used for storing message data
type MessageGroupSummary struct {
	AccountId int64
	Nickname  string
	Messages  []*MessageSummary
	// Hash used for gravatar
	Hash string
	// rendered summary
	Summary string
	// title appears besides the nickname
	Title string
	// used for profile page urls
	Hostname string
}

func NewMessageGroupSummary() *MessageGroupSummary {
	return &MessageGroupSummary{
		Messages: make([]*MessageSummary, 0),
	}
}

func (ms *MessageGroupSummary) Render() (string, error) {
	mt := template.Must(template.New("messagegroup").Parse(templates.MessageGroup))
	gt := template.Must(template.New("gravatar").Parse(templates.Gravatar))
	mt.AddParseTree("gravatar", gt.Tree)

	summary := ""
	for _, ms := range ms.Messages {
		content, err := ms.Render()
		if err != nil {
			return "", err
		}
		summary += content
	}
	ms.Summary = summary
	ms.Hostname = config.MustGet().Hostname

	buf := bytes.NewBuffer([]byte{})
	if err := mt.ExecuteTemplate(buf, "messagegroup", ms); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func (mgs *MessageGroupSummary) AddMessage(ms *MessageSummary) {
	mgs.Messages = append(mgs.Messages, ms)
}

type MessageSummary struct {
	Body string
	// Time is in HH:MM format
	Time string
}

func (ms *MessageSummary) Render() (string, error) {
	mt := template.Must(template.New("message").Parse(templates.Message))
	buf := bytes.NewBuffer([]byte{})

	if err := mt.ExecuteTemplate(buf, "message", ms); err != nil {
		return "", err
	}

	return buf.String(), nil
}
