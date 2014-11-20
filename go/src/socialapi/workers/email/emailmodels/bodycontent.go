package emailmodels

import (
	"bytes"
	"socialapi/workers/email/templates"
	"text/template"
)

type BodyContent struct {
	// Stores channel title
	Title string
	// Rendered summary of messages
	Summary string
	// MessageSummaries are in descending order
	MessageGroups []*MessageGroupSummary
}

func NewBodyContent() *BodyContent {
	return &BodyContent{
		MessageGroups: make([]*MessageGroupSummary, 0),
	}
}

func (bc *BodyContent) AddMessageGroup(mg *MessageGroupSummary) {
	bc.MessageGroups = append(bc.MessageGroups, mg)
}

func (bc *BodyContent) Render() (string, error) {
	body := ""
	for _, mg := range bc.MessageGroups {
		content, err := mg.Render()
		if err != nil {
			return "", err
		}
		body += content
	}

	bt := template.Must(template.New("body").Parse(templates.Channel))

	bc.Summary = body

	buf := bytes.NewBuffer([]byte{})
	if err := bt.ExecuteTemplate(buf, "body", bc); err != nil {
		return "", err
	}

	return buf.String(), nil
}
