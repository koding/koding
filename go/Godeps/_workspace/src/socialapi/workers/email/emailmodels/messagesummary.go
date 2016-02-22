package emailmodels

import (
	"bytes"
	"socialapi/workers/email/templates"
	"text/template"
	"time"
)

type MessageSummary struct {
	Nickname string
	Body     string
	// Time is in HH:MM format
	Time            string
	IsNicknameShown bool
}

func NewMessageSummary(nickname string, timezoneOffset int, body string, createdAt time.Time) *MessageSummary {
	isNicknameShown := false
	if nickname != "" {
		isNicknameShown = true
	}

	loc := time.FixedZone("", timezoneOffset*-60)

	createDate := createdAt
	if loc != nil {
		createDate = createDate.In(loc)
	}

	return &MessageSummary{
		Nickname:        nickname,
		Body:            body,
		Time:            createDate.Format(TimeLayout),
		IsNicknameShown: isNicknameShown,
	}
}

func (ms *MessageSummary) Render() (string, error) {
	mt := template.Must(template.New("message").Parse(templates.Message))
	var buf bytes.Buffer

	escapedBody := template.HTMLEscapeString(ms.Body)
	ms.Body = escapedBody

	if err := mt.ExecuteTemplate(&buf, "message", ms); err != nil {
		return "", err
	}

	return buf.String(), nil
}
