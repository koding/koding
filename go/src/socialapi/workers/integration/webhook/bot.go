package webhook

import (
	"socialapi/models"
	"strconv"
)

const botNick = "bot"

type Bot struct {
	account *models.Account
}

type Message struct {
	Body                 string // TODO check for XSS
	ChannelId            int64
	ChannelIntegrationId int64
	Username             string
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
