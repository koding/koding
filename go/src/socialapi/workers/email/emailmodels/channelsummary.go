package emailmodels

import (
	"bytes"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
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
	AwaySince    time.Time
	Participants []models.ChannelParticipant
	Purpose      string
	Name         string
	Hostname     string

	BodyContent
}

func NewChannelSummary(a *models.Account, ch *models.Channel, awaySince time.Time, timezone string) (*ChannelSummary, error) {

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

	participants, err := fetchParticipants(a, ch)
	if err != nil {
		return nil, err
	}

	mss, err := buildMessageSummaries(cms, timezone)
	if err != nil {
		return nil, err
	}

	cs := &ChannelSummary{
		Id:           ch.Id,
		AwaySince:    awaySince,
		UnreadCount:  count,
		Participants: participants,
		Purpose:      ch.Purpose,
		Name:         ch.Name,
		Hostname:     config.MustGet().Hostname,
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
	title, err := cs.getTitle()
	if err != nil {
		return "", err
	}
	cs.Title = title

	var buf bytes.Buffer
	if err := ct.ExecuteTemplate(&buf, "channel", cs); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func (cs *ChannelSummary) getTitle() (string, error) {
	if len(cs.Participants) == 1 {
		return "", nil
	}

	if cs.Purpose != "" {
		return cs.Purpose, nil
	}

	return cs.prepareTitle()
}

func (cs *ChannelSummary) prepareTitle() (string, error) {

	account, err := models.Cache.Account.ById(cs.Participants[0].AccountId)
	if err != nil {
		return "", err
	}

	title := account.Nick
	for i := 1; i < len(cs.Participants)-1; i++ {
		account, err := models.Cache.Account.ById(cs.Participants[i].AccountId)
		if err != nil {
			return "", err
		}
		title += ", " + account.Nick
	}

	account, err = models.Cache.Account.ById(cs.Participants[len(cs.Participants)-1].AccountId)
	if err != nil {
		return "", err
	}

	title += " & " + account.Nick

	return title, nil
}

func fetchLastMessages(a *models.Account, ch *models.Channel, awaySince time.Time) ([]models.ChannelMessage, error) {
	q := request.NewQuery()
	q.From = awaySince
	q.ExcludeField("AccountId", a.Id)
	q.Type = models.Channel_TYPE_PRIVATE_MESSAGE
	cm := models.NewChannelMessage()

	return cm.FetchMessagesByChannelId(ch.Id, q)
}

func fetchChannelMessageCount(a *models.Account, ch *models.Channel, awaySince time.Time) (int, error) {
	q := request.NewQuery()
	q.From = awaySince
	q.ExcludeField("AccountId", a.Id)
	q.Type = models.Channel_TYPE_PRIVATE_MESSAGE
	cm := models.NewChannelMessage()

	return cm.FetchTotalMessageCount(q)
}

// buildMessageSummarries iterates over messages and decorates MessageGroupSummary
// It also groups messages, so if there are two consecutive messages belongs to the same user
// it is grouped under MessageGroupSummary.
func buildMessageSummaries(messages []models.ChannelMessage, timezone string) ([]*MessageGroupSummary, error) {
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

		// add message to message group since their sender accounts are same
		if message.AccountId == currentGroup.AccountId {
			currentGroup.AddMessage(ms, message.CreatedAt)
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
		currentGroup.Timezone = timezone
		currentGroup.AccountId = message.AccountId
		// push the latest message to the new message group
		currentGroup.AddMessage(ms, message.CreatedAt)
	}

	// when last message has different owner append its message group to array
	if len(mss) == 0 || currentGroup.AccountId != mss[len(mss)-1].AccountId {
		mss = append(mss, currentGroup)
	}

	return mss, nil
}

func fetchParticipants(a *models.Account, ch *models.Channel) ([]models.ChannelParticipant, error) {
	cp := models.NewChannelParticipant()
	cp.ChannelId = ch.Id
	query := request.NewQuery()
	query.ShowExempt = false
	participants, err := cp.List(query)
	if err != nil {
		return participants, err
	}

	if len(participants) < 2 {
		return participants, models.ErrParticipantNotFound
	}

	flattenedParticipants := make([]models.ChannelParticipant, 0)
	for _, participant := range participants {
		if participant.AccountId == a.Id {
			continue
		}

		flattenedParticipants = append(flattenedParticipants, participant)
	}

	return flattenedParticipants, nil
}
