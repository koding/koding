package models

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"strconv"
	"time"

	"github.com/jinzhu/gorm"
)

const (
	ChannelRequestMessage_TYPE_INVITE = "invite"
	ChannelRequestMessage_TYPE_JOIN   = "join"
	ChannelRequestMessage_TYPE_LEAVE  = "leave"
	ChannelRequestMessage_TYPE_REJECT = "reject"
	ChannelRequestMessage_TYPE_KICK   = "kick"
	ChannelRequestMessage_TYPE_INIT   = "initiate"
)

type ChannelRequest struct {
	Body            string      `json:"body"`
	Name            string      `json:"name"`
	Payload         gorm.Hstore `json:"payload,omitempty"`
	GroupName       string      `json:"groupName"`
	Recipients      []string
	AccountId       int64  `json:"accountId,string"`
	ChannelId       int64  `json:"channelId,string"`
	RequestData     string `json:"requestData"`
	ClientRequestId string `json:"ClientRequestId"`
	Purpose         string `json:"purpose"`
	TypeConstant    string `json:"type"`
}

func (p *ChannelRequest) Create() (*ChannelContainer, error) {
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
	c := NewChannel()
	c.GroupName = p.GroupName
	c.CreatorId = p.AccountId
	c.Name = RandomName()
	c.TypeConstant = p.TypeConstant
	c.Purpose = p.Purpose
	c.Payload = p.Payload

	if p.Name != "" {
		c.Name = p.Name
	}

	if err := c.Create(); err != nil {
		return nil, err
	}

	groupChannel, err := Cache.Channel.ByGroupName(c.GroupName)
	if err != nil {
		return nil, err
	}

	// add participants to the channel
	for _, participantId := range participantIds {
		// users should be in regarding group channel
		if err := checkForGroupParticipation(groupChannel, participantId); err != nil {
			return nil, err
		}

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

	return p.buildInitContainer(c, participantIds)
}

func checkForGroupParticipation(groupChannel *Channel, participantId int64) error {
	// everyone is a member of koding group
	if groupChannel.GroupName == Channel_KODING_NAME {
		return nil
	}

	isParticipant, err := groupChannel.IsParticipant(participantId)
	if err != nil {
		return nil
	}

	if !isParticipant {
		return ErrCannotOpenChannel
	}

	return nil
}

func (p *ChannelRequest) buildInitContainer(c *Channel, participantIds []int64) (*ChannelContainer, error) {

	np := &ChannelRequest{}
	*np = *p

	cmc, err := p.buildContainer(c)
	if err != nil {
		return nil, err
	}

	participantOldIds, err := FetchAccountOldsIdByIdsFromCache(participantIds)
	if err != nil {
		return nil, err
	}

	// set participant count
	cmc.ParticipantCount = len(participantIds)
	// set preview
	cmc.ParticipantsPreview = participantOldIds

	return cmc, nil
}

func (p *ChannelRequest) Send() (*ChannelContainer, error) {
	if err := p.validate(); err != nil {
		return nil, err
	}

	if p.ChannelId == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	// check channel existence
	c, err := Cache.Channel.ById(p.ChannelId)
	if err != nil {
		return nil, err
	}

	// check if sender is whether a participant of conversation
	canOpen, err := c.CanOpen(p.AccountId)
	if err != nil {
		return nil, err
	}

	c.UpdatedAt = time.Now()
	// expensive
	if err = c.Update(); err != nil {
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

	return p.buildContainer(c)
}

func (p *ChannelRequest) Clone() *ChannelRequest {
	clone := new(ChannelRequest)
	*clone = *p

	return clone
}

func (p *ChannelRequest) buildContainer(c *Channel) (*ChannelContainer, error) {
	cmc := NewChannelContainer()
	cmc.Channel = c
	cmc.IsParticipant = true
	cmc.AddAccountOldId()
	if cmc.Err != nil {
		return nil, cmc.Err
	}

	return cmc, nil
}

func (p *ChannelRequest) validate() error {
	if p.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if p.GroupName == "" {
		p.GroupName = Channel_KODING_NAME
	}

	if p.TypeConstant == "" {
		return ErrChannelTypeConstantRequired
	}

	return nil
}

// TODO refactor this function to use postgres
func (p *ChannelRequest) obtainParticipantIds() ([]int64, error) {
	participantIds := make([]int64, len(p.Recipients))
	for i, participantName := range p.Recipients {
		// get account from mongo
		account, err := modelhelper.GetAccount(participantName)
		if err != nil {
			return nil, err
		}

		a := NewAccount()
		socialApiId, _ := account.GetSocialApiId()

		a.Id = socialApiId
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

func formatParticipantIds(participantIds []int64) string {
	pids := make([]string, len(participantIds)-1)

	// exclude first participant since it is the private channel owner
	for i, participantId := range participantIds[1:] {
		accountId := strconv.FormatInt(participantId, 10)
		pids[i] = accountId
	}

	result, _ := json.Marshal(pids)

	return string(result)
}

func (p *ChannelRequest) PopulateAddedBy(addedBy int64) {
	if p.Payload == nil {
		p.Payload = gorm.Hstore{}
	}

	addedByStr := strconv.FormatInt(addedBy, 10)
	p.Payload["addedBy"] = &addedByStr
}
