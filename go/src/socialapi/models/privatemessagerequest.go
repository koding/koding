package models

import (
	"koding/db/mongodb/modelhelper"
	"time"
)

type PrivateMessageRequest struct {
	Body            string `json:"body"`
	GroupName       string `json:"groupName"`
	Recipients      []string
	AccountId       int64  `json:"accountId,string"`
	ChannelId       int64  `json:"channelId,string"`
	RequestData     string `json:"requestData"`
	ClientRequestId string `json:"ClientRequestId"`
	Purpose         string `json:"purpose"`
}

type ChatActivity interface {
	GetType() string
	GetBody(*PrivateMessageRequest) string
}

type ChatMessage struct{}

type ChatJoin struct {
	AddedBy string
}

type ChatLeave struct{}

func (cm ChatMessage) GetType() string {
	return ChannelMessage_TYPE_PRIVATE_MESSAGE
}

func (cm ChatMessage) GetBody(p *PrivateMessageRequest) string {
	return p.Body
}

func (cm ChatJoin) GetType() string {
	return ChannelMessage_TYPE_JOIN
}

func (cm ChatJoin) GetBody(p *PrivateMessageRequest) string {
	return "join"
}

func (cm ChatLeave) GetType() string {
	return ChannelMessage_TYPE_LEAVE
}

func (cm ChatLeave) GetBody(p *PrivateMessageRequest) string {
	return "leave"
}

func (p *PrivateMessageRequest) Create() (*ChannelContainer, error) {
	// validate the request
	if err := p.validate(); err != nil {
		return nil, err
	}

	// fetch participants
	participantIds, err := p.obtainParticipantIds()
	if err != nil {
		return nil, err
	}

	// create the channel
	c := NewPrivateMessageChannel(p.AccountId, p.GroupName)
	c.Purpose = p.Purpose
	if err := c.Create(); err != nil {
		return nil, err
	}

	a := NewAccount()
	if err := a.ById(p.AccountId); err != nil {
		return nil, err
	}

	// add participants to tha channel
	for _, participantId := range participantIds {
		cp, err := c.AddParticipant(participantId)
		if err != nil {
			continue
		}

		if participantId != p.AccountId {
			continue
		}

		// do not show unread count to the creator of the private message
		oneSecondLater := time.Now().UTC().Add(time.Second * 1)
		// do not show unread count as 1 to user
		err = cp.RawUpdateLastSeenAt(oneSecondLater)
		if err != nil {
			return nil, err
		}
	}

	// create private message
	cmc, err := p.handlePrivateMessageCreation(c)
	if err != nil {
		return nil, err
	}

	participantOldIds, err := FetchAccountOldsIdByIdsFromCache(participantIds)
	if err != nil {
		// we can ignore the error, wont cause trouble for the user
	}

	// set participant count
	cmc.ParticipantCount = len(participantIds)
	// set preview
	cmc.ParticipantsPreview = participantOldIds

	return cmc, nil
}

func (p *PrivateMessageRequest) Send() (*ChannelContainer, error) {
	if err := p.validate(); err != nil {
		return nil, err
	}

	if p.ChannelId == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	// check channel existence
	c, err := ChannelById(p.ChannelId)
	if err != nil {
		return nil, err
	}

	// check if sender is whether a participant of conversation
	canOpen, err := c.CanOpen(p.AccountId)
	if err != nil {
		return nil, err
	}

	if !canOpen {
		return nil, ErrCannotOpenChannel
	}

	cp, err := c.FetchParticipant(p.AccountId)
	if err != nil {
		return nil, err
	}

	oneSecondLater := time.Now().UTC().Add(time.Second * 1)
	// do not show unread count as 1 to user
	err = cp.RawUpdateLastSeenAt(oneSecondLater)
	if err != nil {
		return nil, err
	}

	return p.handlePrivateMessageCreation(c)
}

func (p *PrivateMessageRequest) handlePrivateMessageCreation(c *Channel) (*ChannelContainer, error) {
	cm, err := p.createMessage(c.Id)
func (p *PrivateMessageRequest) Clone() *PrivateMessageRequest {
	clone := new(PrivateMessageRequest)
	*clone = *p

	return clone
}

	if err != nil {
		return nil, err
	}

	// add message to the channel
	_, err = c.AddMessage(cm.Id)
	if err != nil {
		return nil, err
	}

	lastMessageContainer, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return nil, err
	}

	cmc := NewChannelContainer()
	cmc.Channel = c
	cmc.IsParticipant = true
	cmc.LastMessage = lastMessageContainer
	cmc.LastMessage.Message.ClientRequestId = p.ClientRequestId

	return cmc, nil
}

func (p *PrivateMessageRequest) validate() error {
	if p.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if p.GroupName == "" {
		p.GroupName = Channel_KODING_NAME
	}

	return nil
}

// TODO refactor this function to use postgres
func (p *PrivateMessageRequest) obtainParticipantIds() ([]int64, error) {
	participantIds := make([]int64, len(p.Recipients))
	for i, participantName := range p.Recipients {
		// get account from mongo
		account, err := modelhelper.GetAccount(participantName)
		if err != nil {
			return nil, err
		}

		a := NewAccount()
		a.Id = account.SocialApiId
		a.OldId = account.Id.Hex()
		a.Nick = account.Profile.Nickname
		// fetch or create social api id
		if a.Id == 0 {
			if err := a.FetchOrCreate(); err != nil {
				return nil, err
			}
		}
		participantIds[i] = a.Id
	}

	// append creator to the recipients
	participantIds = prependCreatorId(participantIds, p.AccountId)

	// author and atleast one recipient should be in the
	// recipient list
	if len(participantIds) < 1 {
		// user can send private message to themself
		return nil, ErrRecipientsNotDefined
	}

	return participantIds, nil
}

func prependCreatorId(participants []int64, authorId int64) []int64 {
	participantIds := make([]int64, 0)
	participantIds = append(participantIds, authorId)

	for _, participant := range participants {
		if participant == authorId {
			continue
		}

		participantIds = append(participantIds, participant)
	}

	return participantIds
}

func (p *PrivateMessageRequest) createMessage(channelId int64) (*ChannelMessage, error) {
	cm := NewChannelMessage()
	cm.Body = p.Body
	cm.TypeConstant = ChannelMessage_TYPE_PRIVATE_MESSAGE
	cm.AccountId = p.AccountId
	cm.InitialChannelId = channelId
	if err := cm.Create(); err != nil {
		return nil, err
	}

	return cm, nil
}
