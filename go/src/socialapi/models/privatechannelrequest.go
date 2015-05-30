package models

import (
	"encoding/json"
	"koding/db/mongodb/modelhelper"
	"strconv"
	"time"

	"github.com/jinzhu/gorm"
)

const (
	PrivateMessageSystem_TYPE_INVITE = "invite"
	PrivateMessageSystem_TYPE_JOIN   = "join"
	PrivateMessageSystem_TYPE_LEAVE  = "leave"
	PrivateMessageSystem_TYPE_REJECT = "reject"
	PrivateMessageSystem_TYPE_KICK   = "kick"
	PrivateMessageSystem_TYPE_INIT   = "initiate"
)

type PrivateChannelRequest struct {
	Body            string      `json:"body"`
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

func (p *PrivateChannelRequest) SetSystemMessageType(systemType string) {
	if p.Payload == nil {
		p.Payload = gorm.Hstore{}
	}

	if systemType != "" {
		p.Payload["systemType"] = &systemType
	}
}

func (p *PrivateChannelRequest) Create() (*ChannelContainer, error) {
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
	c := NewPrivateChannel(p.AccountId, p.GroupName, p.TypeConstant)
	c.Purpose = p.Purpose
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
		oneSecondLater := time.Now().UTC().Add(time.Second * 1)
		// do not show unread count as 1 to user
		err = cp.RawUpdateLastSeenAt(oneSecondLater)
		if err != nil {
			return nil, err
		}
	}

	return p.buildInitContainer(c, participantIds)
}

func (p *PrivateChannelRequest) buildInitContainer(c *Channel, participantIds []int64) (*ChannelContainer, error) {

	np := &PrivateChannelRequest{}
	*np = *p
	lastMessage, err := p.AddInitActivity(c, participantIds)
	if err != nil {
		return nil, err
	}

	if np.Body != "" {
		var err error
		// create private message
		lastMessage, err = np.AddMessage(c)
		if err != nil {
			return nil, err
		}
	}

	cmc, err := p.buildContainer(c, lastMessage)
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

func (p *PrivateChannelRequest) Send() (*ChannelContainer, error) {
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

	cm, err := p.AddMessage(c)
	if err != nil {
		return nil, err
	}

	return p.buildContainer(c, cm)
}

func (p *PrivateChannelRequest) Clone() *PrivateChannelRequest {
	clone := new(PrivateChannelRequest)
	*clone = *p

	return clone
}

func (p *PrivateChannelRequest) AddMessage(c *Channel) (*ChannelMessage, error) {
	return p.createActivity(c, ChannelMessage_TYPE_PRIVATE_MESSAGE)
}

func (p *PrivateChannelRequest) AddJoinActivity(c *Channel, addedBy int64) error {
	if p.AccountId != addedBy && addedBy != 0 {
		addedByStr := strconv.FormatInt(addedBy, 10)
		p.Payload["addedBy"] = &addedByStr
	}

	_, err := p.createActivity(c, ChannelMessage_TYPE_SYSTEM)

	return err
}

func (p *PrivateChannelRequest) AddLeaveActivity(c *Channel) error {
	_, err := p.createActivity(c, ChannelMessage_TYPE_SYSTEM)

	return err
}

func (p *PrivateChannelRequest) AddInitActivity(c *Channel, participantIds []int64) (*ChannelMessage, error) {
	if len(participantIds) == 0 {
		return nil, nil
	}

	if p.Payload == nil {
		p.Payload = gorm.Hstore{}
	}

	if len(participantIds) > 0 {
		payload := formatParticipantIds(participantIds)
		p.Payload["initialParticipants"] = &payload
		activity := PrivateMessageSystem_TYPE_INIT
		p.Payload["systemType"] = &activity
	}

	cm, err := p.createActivity(c, ChannelMessage_TYPE_SYSTEM)
	if err != nil {
		return nil, err
	}

	return cm, nil
}

func (p *PrivateChannelRequest) createActivity(c *Channel, typeConstant string) (*ChannelMessage, error) {
	cm, err := p.createMessage(c.Id, typeConstant)
	if err != nil {
		return nil, err
	}

	// add message to the channel
	cm.ClientRequestId = p.ClientRequestId
	_, err = c.AddMessage(cm)
	if err != nil {
		return nil, err
	}

	return cm, nil
}

func (p *PrivateChannelRequest) buildContainer(c *Channel, cm *ChannelMessage) (*ChannelContainer, error) {

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

func (p *PrivateChannelRequest) validate() error {
	if p.AccountId == 0 {
		return ErrAccountIdIsNotSet
	}

	if p.GroupName == "" {
		p.GroupName = Channel_KODING_NAME
	}

	if p.TypeConstant == "" {
		p.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE
	}

	return nil
}

// TODO refactor this function to use postgres
func (p *PrivateChannelRequest) obtainParticipantIds() ([]int64, error) {
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

func getBody(p *PrivateChannelRequest, typeConstant string) string {
	switch typeConstant {
	case ChannelMessage_TYPE_PRIVATE_MESSAGE:
		return p.Body
	case ChannelMessage_TYPE_SYSTEM:
		return "system"
	}

	return ""
}

func (p *PrivateChannelRequest) createMessage(channelId int64, typeConstant string) (*ChannelMessage, error) {
	cm := NewChannelMessage()
	cm.Body = getBody(p, typeConstant)
	cm.TypeConstant = typeConstant
	cm.AccountId = p.AccountId
	cm.InitialChannelId = channelId
	cm.Payload = p.Payload

	if err := cm.Create(); err != nil {
		return nil, err
	}

	return cm, nil
}

func formatParticipantIds(participantIds []int64) string {
	pids := make([]string, len(participantIds)-1)

	// exclude first participant since it is the private channel owner
	for i, participantId := range participantIds[1:len(participantIds)] {
		accountId := strconv.FormatInt(participantId, 10)
		pids[i] = accountId
	}

	result, _ := json.Marshal(pids)

	return string(result)
}
