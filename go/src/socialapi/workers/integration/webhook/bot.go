package webhook

import (
	"socialapi/models"
	"strconv"

	"github.com/koding/bongo"
)

const botNick = "bot"

type Bot struct {
	account *models.Account
}

type Message struct {
	Body                 string // TODO check for XSS
	ChannelId            int64  `json:"channelId,string"`
	ChannelIntegrationId int64  `json:"channelIntegrationId,string"`
}

func NewBot() (*Bot, error) {
	acc := models.NewAccount()
	if err := acc.ByNick(botNick); err != nil {
		return nil, err
	}

	return &Bot{account: acc}, nil
}

func (b *Bot) SendMessage(m *Message) error {
	cm, err := b.createMessage(m)
	if err != nil {
		return err
	}

	return b.createMessageList(cm, m.ChannelId)
}

func (b *Bot) createMessage(m *Message) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	cm.AccountId = b.account.Id
	cm.InitialChannelId = m.ChannelId
	cm.Body = m.Body
	cm.TypeConstant = models.ChannelMessage_TYPE_BOT
	tid := strconv.FormatInt(m.ChannelIntegrationId, 10)
	cm.SetPayload("channelIntegrationId", tid)

	return cm, cm.Create()
}

func (b *Bot) createMessageList(cm *models.ChannelMessage, channelId int64) error {
	cml := models.NewChannelMessageList()
	cml.ChannelId = channelId
	cml.MessageId = cm.Id

	return cml.Create()
}

func (b *Bot) FetchBotChannel(a *models.Account, group *models.Channel) (*models.Channel, error) {

	c, err := b.fetchOrCreateChannel(a, group.GroupName)
	if err != nil {
		return nil, err
	}

	// add user as participant
	_, err = c.AddParticipant(a.Id)
	if err == models.ErrAccountIsAlreadyInTheChannel {
		return c, nil
	}

	return c, err
}

func (b *Bot) fetchOrCreateChannel(a *models.Account, groupName string) (*models.Channel, error) {

	// fetch or create channel
	c, err := b.fetchBotChannel(a, groupName)
	if err == bongo.RecordNotFound {
		return b.createBotChannel(a, groupName)
	}

	if err != nil {
		return nil, err
	}

	return c, err
}

func (b *Bot) fetchBotChannel(a *models.Account, groupName string) (*models.Channel, error) {

	c := models.NewChannel()
	selector := map[string]interface{}{
		"creator_id":    a.Id,
		"type_constant": models.Channel_TYPE_BOT,
		"group_name":    groupName,
	}

	// if err is nil
	// it means we already have that channel
	err := c.One(bongo.NewQS(selector))

	return c, err
}

func (b *Bot) createBotChannel(a *models.Account, groupName string) (*models.Channel, error) {
	c := models.NewChannel()

	c.CreatorId = a.Id
	c.GroupName = groupName
	c.Name = models.RandomName()
	c.TypeConstant = models.Channel_TYPE_BOT

	err := c.Create()

	return c, err
}
