package emailmodels

import (
	"fmt"
	"strings"
	"text/template"
	"time"
)

type Message interface {
	ToMap() map[string]interface{}
}

type MailerNotification struct {
	Hostname         string
	FirstName        string
	Username         string
	Email            string
	MessageType      string
	UnsubscribeToken string
	Messages         []Message
}

func (m *MailerNotification) ToMap() map[string]interface{} {
	messages := []map[string]interface{}{}

	for _, msg := range m.Messages {
		messages = append(messages, msg.ToMap())
	}

	unsubscribeLink := buildUnsubscribeLink(m.Hostname, m.UnsubscribeToken, m.Email)
	unsubscribeAllLink := buildUnsubscribeAllLink(m.Hostname, m.UnsubscribeToken, m.Email)

	return map[string]interface{}{
		"messages":           messages,
		"firstName":          m.FirstName,
		"unsubscribeLink":    unsubscribeLink,
		"unsubscribeAllLink": unsubscribeAllLink,
	}
}

//----------------------------------------------------------
// Implementations of `Message`
//----------------------------------------------------------

type NotificationMessage struct {
	Hostname       string
	Actor          string
	ActorHash      string
	ActorSlug      string
	Message        string
	MessageSlug    string
	Action         string
	ActionType     string
	CreatedAt      time.Time
	TimezoneOffset int
}

func (n *NotificationMessage) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"actor":       n.Actor,
		"message":     convertCodeBlocksToPre(n.Message),
		"action":      n.Action,
		"actionType":  n.ActionType,
		"actorAvatar": buildActorAvatar(n.ActorHash),
		"actorLink":   buildActorLink(n.Hostname, n.ActorSlug),
		"messageLink": buildMessageLink(n.Hostname, n.MessageSlug),
		"createdAt":   formatMessageCreatedAt(n.CreatedAt, n.TimezoneOffset),
	}
}

type PrivateMessageChannel struct {
	NestedMessages []*PrivateMessage
	Subtitle       string
	ActorHash      string
}

func (p *PrivateMessageChannel) ToMap() map[string]interface{} {
	results := []map[string]interface{}{}

	for _, m := range p.NestedMessages {
		results = append(results, m.ToMap())
	}

	return map[string]interface{}{
		"nestedMessages": results,
		"subtitle":       p.Subtitle,
		"actorAvatar":    buildActorAvatar(p.ActorHash),
	}
}

type PrivateMessage struct {
	CreatedAt string
	Actor     string
	Message   string
}

func (p *PrivateMessage) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"actor":     p.Actor,
		"message":   convertCodeBlocksToPre(p.Message),
		"createdAt": p.CreatedAt,
	}
}

//----------------------------------------------------------
// Helpers
//----------------------------------------------------------

func formatMessageCreatedAt(createdAt time.Time, timezoneOffset int) string {
	loc := time.FixedZone("", timezoneOffset*-60)

	createdDate := createdAt
	if loc != nil {
		createdDate = createdDate.In(loc)
	}

	return createdDate.Format(TimeLayout)
}

func buildActorAvatar(hash string) string {
	return "https://gravatar.com/avatar/" + hash + "?size=35&d=https%3A%2F%2Fkoding-cdn.s3.amazonaws.com%2Fsquare-avatars%2Fdefault.avatar.35.png"
}

func buildActorLink(hostname, actor string) string {
	return fmt.Sprintf("%s/%s", hostname, actor)
}

func buildMessageLink(hostname, slug string) string {
	return fmt.Sprintf("%s/Activity/Post/%s", hostname, slug)
}

func buildUnsubscribeLink(hostname, token, email string) string {
	return fmt.Sprintf("%s/Unsubscribe/%s/%s", hostname, token, email)
}

func buildUnsubscribeAllLink(hostname, token, email string) string {
	link := buildUnsubscribeLink(hostname, token, email)
	return fmt.Sprintf("%s/all", link)
}

// Convert ```.``` blocks into <pre>.</pre> so email clients can render
// it. This is a lighter weight option than using a full featured
// markdown library here. Simple trick to understanding how it works is
// realizing odd elements are inside code blocks, even elements are outside.
//
// Examples:
//		convertCodeBlocksToPre("```inside``` output")
//    #=> "<pre>inside</pre> output"
func convertCodeBlocksToPre(input string) string {
	output := ""
	splitInput := strings.Split(input, "```")

	for index, str := range splitInput {
		if index%2 == 0 {
			output += template.HTMLEscapeString(str)
		} else {
			output += "<pre>" + str + "</pre>"
		}
	}

	return output
}
