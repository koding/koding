package emailmodels

import (
	"bytes"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/email/templates"
	"text/template"
	"time"
)

const (
	TimeLayout   = "3:04 PM"
	MessageLimit = 3
)

// ChannelSummary used for storing channel purpose and messages
type ChannelSummary struct {
	// Stores channel id
	Id int64
	// Unread count stores unread message count in the idle time
	UnreadCount int
	// AwaySince returns the oldest message in notification queue
	AwaySince time.Time

	BodyContent
}

func NewChannelSummary(a *models.Account, ch *models.Channel, awaySince time.Time) (*ChannelSummary, error) {
	cms, err := fetchLastMessages(a, ch, awaySince)
	if err != nil {
		return nil, err
	}

	count, err := fetchChannelMessageCount(a, ch, awaySince)
	if err != nil {
		return nil, err
	}

	mss, err := buildMessageSummaries(cms)
	if err != nil {
		return nil, err
	}

	cs := &ChannelSummary{
		Id:          ch.Id,
		AwaySince:   awaySince,
		UnreadCount: count,
	}

	cs.MessageGroups = mss

	return cs, nil
}

func (cs *ChannelSummary) Render() string {
	body := ""
	for _, message := range cs.MessageGroups {
		body += message.Render()
	}

	ct := template.Must(template.New("channel").Parse(templates.Channel))

	cs.Summary = body
	cs.Title = getTitle(cs.UnreadCount)

	buf := bytes.NewBuffer([]byte{})
	ct.ExecuteTemplate(buf, "channel", cs)

	return buf.String()
}

func getTitle(messageCount int) string {
	messagePlural := ""
	if messageCount > 1 {
		messagePlural = "s"
	}

	return fmt.Sprintf("You have %d new message%s:", messageCount, messagePlural)
}

func fetchLastMessages(a *models.Account, ch *models.Channel, awaySince time.Time) ([]models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.InitialChannelId = ch.Id
	cm.AccountId = a.Id
	cm.CreatedAt = awaySince

	return cm.FetchLatestChannelMessages(MessageLimit)
}

func fetchChannelMessageCount(a *models.Account, ch *models.Channel, awaySince time.Time) (int, error) {
	cm := models.NewChannelMessage()
	cm.InitialChannelId = ch.Id
	cm.AccountId = a.Id

	return cm.FetchChannelMessageCountSince(awaySince)
}

func buildMessageSummaries(messages []models.ChannelMessage) ([]*MessageGroupSummary, error) {
	mss := make([]*MessageGroupSummary, 0)
	currentGroup := NewMessageGroupSummary()
	if len(messages) == 0 {
		return mss, nil
	}

	for _, message := range messages {
		// create new message summary
		ms := new(MessageSummary)
		ms.Body = message.Body
		ms.Time = message.CreatedAt.Format(TimeLayout)

		// if message has the same creator with the previous one
		if message.AccountId == currentGroup.AccountId {
			currentGroup.AddMessage(ms)
			continue
		}
		mg := NewMessageGroupSummary()
		// if current group has valid data
		if currentGroup.AccountId != 0 {
			*mg = *currentGroup
			mss = append(mss, mg)
		}

		currentGroup = NewMessageGroupSummary()
		a, err := models.FetchAccountById(message.AccountId)
		if err != nil {
			return mss, err
		}
		currentGroup.Nickname = a.Nick
		ma, err := modelhelper.GetAccountById(a.OldId)
		if err != nil {
			return mss, err
		}
		currentGroup.Hash = ma.Profile.Hash
		currentGroup.AccountId = message.AccountId
		currentGroup.AddMessage(ms)
	}

	if len(mss) == 0 || currentGroup.AccountId != mss[len(mss)-1].AccountId {
		mss = append(mss, currentGroup)
	}

	return mss, nil
}
