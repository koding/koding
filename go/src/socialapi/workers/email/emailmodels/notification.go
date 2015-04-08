package emailmodels

import (
	"fmt"
	"time"
)

type Message interface {
	ToMap() map[string]interface{}
}

type MailerNotification struct {
	FirstName   string
	Username    string
	Email       string
	MessageType string
	Messages    []Message
}

func (m *MailerNotification) ToMap() map[string]interface{} {
	messages := []map[string]interface{}{}

	for _, msg := range m.Messages {
		messages = append(messages, msg.ToMap())
	}

	return map[string]interface{}{
		"messages": messages, "firstName": m.FirstName,
	}
}

//----------------------------------------------------------
// Implementations of `Message`
//----------------------------------------------------------

type NotificationMessage struct {
	Hostname       string
	Actor          string
	ActorHash      string
	ActorLink      string
	ActorSlug      string
	Message        string
	MessageSlug    string
	Action         string
	ObjectType     string
	CreatedAt      time.Time
	TimezoneOffset int
}

func (n *NotificationMessage) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"actor":       n.Actor,
		"message":     n.Message,
		"action":      n.Action,
		"objectType":  n.ObjectType,
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
		"nestedMessages": results, "subtitle": p.Subtitle,
		"actorAvatar": buildActorAvatar(p.ActorHash),
	}
}

type PrivateMessage struct {
	CreatedAt string
	Actor     string
	Message   string
}

func (p *PrivateMessage) ToMap() map[string]interface{} {
	return map[string]interface{}{
		"createdAt": p.CreatedAt, "actor": p.Actor, "message": p.Message,
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
