package emailmodels

import (
	"bytes"
	"errors"
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
	TimeLayout       = "3:04 PM"
	MessageLimit     = 3
	ParticipantLimit = 3
)

var ErrMessageNotFound = errors.New("message not found")

// ChannelSummary used for storing channel purpose and messages
type ChannelSummary struct {
	// Stores channel id
	Id int64
	// Unread count stores unread message count in the idle time
	UnreadCount int
	// AwaySince returns the oldest message in notification queue
	AwaySince        time.Time
	Participants     []models.ChannelParticipant
	ParticipantCount int
	Purpose          string
	ChannelId        string
	Hostname         string
	IsGroupChannel   bool
	Link             string
	Image            string
	Summary          string

	BodyContent
}

type ChannelImage struct {
	Hash string
}

func (ci *ChannelImage) Render() (string, error) {
	return ci.Hash, nil
}

func NewChannelSummary(a *models.Account, ch *models.Channel, awaySince time.Time, timezoneOffset int) (*ChannelSummary, error) {
	cms, err := fetchLastMessages(a, ch, awaySince)
	if err != nil {
		return nil, err
	}

	if len(cms) == 0 {
		return nil, ErrMessageNotFound
	}

	// fix the ordering problem of the messages
	orderedCms := make([]models.ChannelMessage, len(cms))
	// swap the order
	for i, cm := range cms {
		// head becomes last, last becomes first
		orderedCms[len(cms)-i-1] = cm
	}

	count, err := fetchChannelMessageCount(a, ch, awaySince)
	if err != nil {
		return nil, err
	}

	if count == 0 {
		return nil, ErrMessageNotFound
	}

	participants, err := fetchParticipants(a, ch)
	if err != nil {
		return nil, err
	}

	totalParticipantCount, err := fetchParticipantCount(ch)
	if err != nil {
		return nil, err
	}

	isGroupChannel := false
	if len(participants) > 1 {
		isGroupChannel = true
	}

	cs := &ChannelSummary{
		Id:               ch.Id,
		AwaySince:        awaySince,
		UnreadCount:      count,
		Participants:     participants,
		ParticipantCount: totalParticipantCount,
		Purpose:          ch.Purpose,
		ChannelId:        strconv.FormatInt(ch.Id, 10),
		Hostname:         config.MustGet().Protocol + "//" + config.MustGet().Hostname,
		IsGroupChannel:   isGroupChannel,
	}
	cs.BodyContent.TimezoneOffset = timezoneOffset

	if isGroupChannel {
		cs.BodyContent.IsNicknameShown = true
	}

	if err := cs.BodyContent.AddMessages(orderedCms); err != nil {
		return nil, err
	}

	if err := cs.prepareLink(); err != nil {
		return nil, err
	}

	return cs, nil
}

func (cs *ChannelSummary) RenderImage() (string, error) {
	if len(cs.Participants) < 1 {
		return "", nil
	}

	var nickname string
	var err error

	// do not use any images for group conversations
	if !cs.IsGroupChannel {
		nickname, err = getAccountNickname(cs.Participants[0].AccountId)
		if err != nil {
			return "", err
		}

	} else if len(cs.MessageSummaries) > 0 {
		nickname = cs.MessageSummaries[0].Nickname
	}

	return cs.renderGravatar(nickname)
}

func (cs *ChannelSummary) renderGravatar(nickname string) (string, error) {

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

	messageUrl := fmt.Sprintf("%s/Activity/Message/%s", cs.Hostname, cs.ChannelId)

	cs.Link = fmt.Sprintf(`%s sent you <a href="%s">%d message%s:</a>`, titleUrl, messageUrl, cs.UnreadCount, getPluralSuffix(cs.UnreadCount))

	return nil
}

// prepareGroupChannelTitle gets purpose as the channel title if it exists, or concatenates
// latest participant nicknames for composing a title
func (cs *ChannelSummary) prepareGroupChannelLink() error {
	prefix := "Latest messages from your group conversation"
	if cs.Purpose != "" {
		cs.Title = cs.Purpose
		prefix += ":"
	} else {
		if len(cs.Participants) == 0 {
			return nil
		}

		prefix += " with"

		nicknames := make([]string, 0)

		for i := 0; i < ParticipantLimit && i < len(cs.Participants); i++ {
			account, err := models.Cache.Account.ById(cs.Participants[i].AccountId)
			if err != nil {
				return err
			}

			nicknames = append(nicknames, account.Nick)
		}

		cs.Title = cs.prepareTitleWithNicknames(nicknames)
	}

	titleUrl := fmt.Sprintf(`<a href="%s/Activity/Message/%s">%s</a>`, cs.Hostname, cs.ChannelId, cs.Title)
	cs.Link = fmt.Sprintf("%s %s", prefix, titleUrl)

	return nil
}

func (cs *ChannelSummary) prepareTitleWithNicknames(nicknames []string) string {
	// not possible but still being defensive
	if len(nicknames) == 1 {
		return nicknames[0]
	}

	title := ""
	for i, nickname := range nicknames {
		if i == len(nicknames)-1 {
			break
		}

		title = fmt.Sprintf("%s %s,", title, nickname)
	}

	// remove last comma
	title = title[:len(title)-1]

	if cs.ParticipantCount <= ParticipantLimit {
		return fmt.Sprintf("%s & %s", title, nicknames[len(nicknames)-1])
	}

	return fmt.Sprintf("%s, %s & %d more", title, nicknames[len(nicknames)-1], cs.ParticipantCount-ParticipantLimit)
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
	q.GroupChannelId = ch.Id

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

func fetchParticipantCount(ch *models.Channel) (int, error) {
	cp := models.NewChannelParticipant()
	cp.ChannelId = ch.Id
	count, err := cp.FetchParticipantCount()
	if err != nil {
		return 0, err
	}

	return count - 1, nil
}

func getPluralSuffix(count int) string {
	if count > 1 {
		return "s"
	}

	return ""
}
