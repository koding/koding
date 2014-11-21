package emailmodels

import (
	"bytes"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/request"
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

	if count == 0 {
		return &ChannelSummary{}, nil
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

func (cs *ChannelSummary) Render() (string, error) {
	body := ""
	for _, message := range cs.MessageGroups {
		content, err := message.Render()
		if err != nil {
			return "", err
		}
		body += content
	}

	ct := template.Must(template.New("channel").Parse(templates.Channel))

	cs.Summary = body
	cs.Title = getTitle(cs.UnreadCount)

	var buf bytes.Buffer
	if err := ct.ExecuteTemplate(&buf, "channel", cs); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func getTitle(messageCount int) string {
	messagePlural := ""
	if messageCount > 1 {
		messagePlural = "s"
	}

	return fmt.Sprintf("You have %d new message%s:", messageCount, messagePlural)
}

func fetchLastMessages(a *models.Account, ch *models.Channel, awaySince time.Time) ([]models.ChannelMessage, error) {
	q := request.NewQuery()
	q.From = awaySince
	q.ExcludeField("AccountId", a.Id)
	cm := models.NewChannelMessage()

	return cm.FetchMessagesByChannelId(ch.Id, q)
}

func fetchChannelMessageCount(a *models.Account, ch *models.Channel, awaySince time.Time) (int, error) {
	q := request.NewQuery()
	q.From = awaySince
	q.ExcludeField("AccountId", a.Id)
	cm := models.NewChannelMessage()

	return cm.FetchTotalMessageCount(q)
}

// buildMessageSummarries iterates over messages and decorates MessageGroupSummary
// It also groups messages, so if there are two consecutive messages belongs to the same user
// it is grouped under MessageGroupSummary.
func buildMessageSummaries(messages []models.ChannelMessage) ([]*MessageGroupSummary, error) {
	mss := make([]*MessageGroupSummary, 0)
	// each consequent user will have another MessageGroup
	currentGroup := NewMessageGroupSummary()
	if len(messages) == 0 {
		return mss, nil
	}

	for _, message := range messages {
		// create new message summary
		ms := new(MessageSummary)
		ms.Body = message.Body
		ms.Time = message.CreatedAt.Format(TimeLayout)

		// add message to message group since their sender accounts are same
		if message.AccountId == currentGroup.AccountId {
			currentGroup.AddMessage(ms)
			continue
		}
		// Different message sender so create a new group
		mg := NewMessageGroupSummary()
		// when currentGroup is not empty and add it to result array
		if currentGroup.AccountId != 0 {
			*mg = *currentGroup
			mss = append(mss, mg)
		}

		// and create a new group
		currentGroup = NewMessageGroupSummary()

		a, err := models.Cache.Account.ById(message.AccountId)
		if err != nil {
			return mss, err
		}
		currentGroup.Nickname = a.Nick
		// TODO this can be fetched from cache but its invalidation needs to be handled as well.
		ma, err := modelhelper.GetAccountById(a.OldId)
		if err != nil {
			return mss, err
		}
		currentGroup.Hash = ma.Profile.Hash
		currentGroup.AccountId = message.AccountId
		// push the latest message to the new message group
		currentGroup.AddMessage(ms)
	}

	// when last message has different owner append its message group to array
	if len(mss) == 0 || currentGroup.AccountId != mss[len(mss)-1].AccountId {
		mss = append(mss, currentGroup)
	}

	return mss, nil
}
