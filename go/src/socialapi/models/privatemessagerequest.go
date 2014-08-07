package models

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/koding/bongo"
)

type PrivateMessageRequest struct {
	Body       string `json:"body"`
	GroupName  string `json:"groupName"`
	Recipients []string
	AccountId  int64 `json:"accountId,string"`
	ChannelId  int64 `json:"channelId,string"`
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
	if err := c.Create(); err != nil {
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
		err = bongo.B.DB.Exec(
			fmt.Sprintf("UPDATE %s SET last_seen_at = ? WHERE id = ?",
				cp.TableName(),
			),
			time.Now().UTC().Add(time.Second*1),
			cp.Id,
		).Error
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
	c := NewChannel()
	if err := c.ById(p.ChannelId); err != nil {
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

	// do not show unread count as 1 to user
	err = bongo.B.DB.Exec(
		fmt.Sprintf("UPDATE %s SET last_seen_at = ? WHERE id = ?",
			cp.TableName(),
		),
		time.Now().UTC().Add(time.Second*1),
		cp.Id,
	).Error
	if err != nil {
		return nil, err
	}

	return p.handlePrivateMessageCreation(c)
}

func (p *PrivateMessageRequest) handlePrivateMessageCreation(c *Channel) (*ChannelContainer, error) {
	cm, err := p.createMessage(c.Id)
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
	participantIds = appendCreatorId(participantIds, p.AccountId)

	// author and atleast one recipient should be in the
	// recipient list
	if len(participantIds) < 1 {
		// user can send private message to themself
		return nil, ErrRecipientsNotDefined
	}

	return participantIds, nil
}

func appendCreatorId(participants []int64, authorId int64) []int64 {
	for _, participant := range participants {
		if participant == authorId {
			return participants
		}
	}

	return append(participants, authorId)
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
