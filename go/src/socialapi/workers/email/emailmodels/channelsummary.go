package emailmodels

import (
	"bytes"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/email/templates"
	"strconv"
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
	AwaySince      time.Time
	Participants   []models.ChannelParticipant
	Purpose        string
	ChannelId      string
	Hostname       string
	IsGroupChannel bool
	Link           string
	Image          string
	Summary        string

	BodyContent
}

type ChannelImage struct {
	Hash string
}

func (ci *ChannelImage) Render() (string, error) {
	if ci.Hash == "" {
		return "", nil
	}

	lt := template.Must(template.New("image").Parse(templates.Gravatar))

	var buf bytes.Buffer
	if err := lt.ExecuteTemplate(&buf, "image", ci); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func NewChannelSummary(a *models.Account, ch *models.Channel, awaySince time.Time, timezone string) (*ChannelSummary, error) {
	fmt.Println("timezone nedir ki", timezone)
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

	isGroupChannel := false
	if len(participants) > 1 {
		isGroupChannel = true
	}

	cs := &ChannelSummary{
		Id:             ch.Id,
		AwaySince:      awaySince,
		UnreadCount:    count,
		Participants:   participants,
		Purpose:        ch.Purpose,
		ChannelId:      strconv.FormatInt(ch.Id, 10),
		Hostname:       config.MustGet().Hostname,
		IsGroupChannel: isGroupChannel,
	}
	cs.BodyContent.Timezone = timezone

	if err := cs.BodyContent.AddMessages(cms); err != nil {
		return nil, err
	}

	if isGroupChannel {
		cs.BodyContent.IsNicknameShown = true
	}

	if err := cs.prepareLink(); err != nil {
		return nil, err
	}

	return cs, nil
}

func (cs *ChannelSummary) Render() (string, error) {
	ct := template.Must(template.New("channel").Parse(templates.Channel))

	var buf bytes.Buffer
	if err := ct.ExecuteTemplate(&buf, "channel", cs); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func (cs *ChannelSummary) RenderImage() (string, error) {
	// do not use any images for group conversations
	if !cs.IsGroupChannel {
		return cs.renderGravatar()
	}

	return "", nil
}

func (cs *ChannelSummary) renderGravatar() (string, error) {
	if len(cs.Participants) < 1 {
		return "", nil
	}

	nickname, err := getAccountNickname(cs.Participants[0].AccountId)
	if err != nil {
		return "", err
	}

	account, err := modelhelper.GetAccount(nickname)
	if err != nil {
		return "", err
	}

	ci := &ChannelImage{}
	ci.Hash = account.Profile.Hash

	return ci.Render()
}

func (cs *ChannelSummary) prepareLink() error {
	if len(cs.Participants) == 1 {
		return cs.prepareDirectMessageLink()
	}

	return cs.prepareGroupChannelLink()
}

func (cs *ChannelSummary) renderTitle() (string, error) {
	lt := template.Must(template.New("channellink").Parse(templates.ChannelLink))

	var buf bytes.Buffer
	if err := lt.ExecuteTemplate(&buf, "channellink", cs); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func getAccountNickname(accountId int64) (string, error) {
	account, err := models.Cache.Account.ById(accountId)
	if err != nil {
		return "", err
	}

	return account.Nick, nil
}

func (cs *ChannelSummary) prepareDirectMessageLink() error {
	nickname, err := getAccountNickname(cs.Participants[0].AccountId)
	if err != nil {
		return err
	}

	cs.Title = nickname

	titleUrl, err := cs.renderTitle()
	if err != nil {
		return err
	}

	cs.Link = fmt.Sprintf("%s sent you %d message%s:", titleUrl, cs.UnreadCount, getPluralSuffix(cs.UnreadCount))

	return nil
}

// prepareGroupChannelTitle gets purpose as the channel title if it exists, or concatenates
// latest participant nicknames for composing a title
func (cs *ChannelSummary) prepareGroupChannelLink() error {
	if cs.Purpose != "" {
		cs.Title = cs.Purpose
	} else {
		if len(cs.Participants) == 0 {
			return nil
		}

		account, err := models.Cache.Account.ById(cs.Participants[0].AccountId)
		if err != nil {
			return err
		}

		title := account.Nick
		for i := 1; i < len(cs.Participants)-1; i++ {
			account, err := models.Cache.Account.ById(cs.Participants[i].AccountId)
			if err != nil {
				return err
			}
			title += ", " + account.Nick
		}

		account, err = models.Cache.Account.ById(cs.Participants[len(cs.Participants)-1].AccountId)
		if err != nil {
			return err
		}

		title += " & " + account.Nick

		cs.Title = title
	}

	titleUrl, err := cs.renderTitle()
	if err != nil {
		return err
	}
	cs.Link = fmt.Sprintf("Latest messages from %s", titleUrl)

	return nil
}

// fetchLastMessage fetches latest channel messages excluding given user's messages.
func fetchLastMessages(a *models.Account, ch *models.Channel, awaySince time.Time) ([]models.ChannelMessage, error) {
	q := request.NewQuery()
	q.From = awaySince
	q.ExcludeField("AccountId", a.Id)
	q.Type = models.Channel_TYPE_PRIVATE_MESSAGE
	q.Limit = 3
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
