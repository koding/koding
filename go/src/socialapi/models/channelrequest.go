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

	// all topic channels under koding, should be public
	if c.TypeConstant == Channel_TYPE_TOPIC && c.GroupName == Channel_KODING_NAME {
		c.PrivacyConstant = Channel_PRIVACY_PUBLIC
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

	typeConstant := ChannelMessage_TYPE_PRIVATE_MESSAGE
	if p.TypeConstant == Channel_TYPE_TOPIC {
		typeConstant = ChannelMessage_TYPE_POST
	}

	return p.buildInitContainer(c, participantIds, typeConstant)
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

func (p *ChannelRequest) buildInitContainer(c *Channel, participantIds []int64, typeConstant string) (*ChannelContainer, error) {

	np := &ChannelRequest{}
	*np = *p
	lastMessage, err := p.AddInitActivity(c, participantIds)
	if err != nil {
		return nil, err
	}

	if np.Body != "" {
		var err error
		// create private message

		lastMessage, err = p.createActivity(c, typeConstant)
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

	typeConstant := ChannelMessage_TYPE_PRIVATE_MESSAGE

	if c.TypeConstant == Channel_TYPE_TOPIC {
		typeConstant = ChannelMessage_TYPE_POST
	}

	cm, err := p.createActivity(c, typeConstant)
	if err != nil {
		return nil, err
	}

	return p.buildContainer(c, cm)
}

func (p *ChannelRequest) Clone() *ChannelRequest {
	clone := new(ChannelRequest)
	*clone = *p

	return clone
}

func (p *ChannelRequest) AddJoinActivity(c *Channel, addedBy int64) error {
	if p.AccountId != addedBy && addedBy != 0 {
		addedByStr := strconv.FormatInt(addedBy, 10)
		p.Payload["addedBy"] = &addedByStr
	}

	_, err := p.createActivity(c, ChannelMessage_TYPE_SYSTEM)

	return err
}

func (p *ChannelRequest) AddLeaveActivity(c *Channel) error {
	_, err := p.createActivity(c, ChannelMessage_TYPE_SYSTEM)

	return err
}

func (p *ChannelRequest) AddInitActivity(c *Channel, participantIds []int64) (*ChannelMessage, error) {
	if len(participantIds) == 0 {
		return nil, nil
	}

	if p.Payload == nil {
		p.Payload = gorm.Hstore{}
	}

	if len(participantIds) > 0 {
		payload := formatParticipantIds(participantIds)
		p.Payload["initialParticipants"] = &payload
		activity := ChannelRequestMessage_TYPE_INIT
		p.Payload["systemType"] = &activity
		p.PopulateAddedBy(c.CreatorId)
	}

	cm, err := p.createActivity(c, ChannelMessage_TYPE_SYSTEM)
	if err != nil {
		return nil, err
	}

	return cm, nil
}

func (p *ChannelRequest) SetSystemMessageType(systemType string) {
	if p.Payload == nil {
		p.Payload = gorm.Hstore{}
	}

	if systemType != "" {
		p.Payload["systemType"] = &systemType
	}
}

func (p *ChannelRequest) createActivity(c *Channel, typeConstant string) (*ChannelMessage, error) {
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

func (p *ChannelRequest) buildContainer(c *Channel, cm *ChannelMessage) (*ChannelContainer, error) {

	lastMessageContainer, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return nil, err
	}

	cm, err = lastMessageContainer.Message.PopulatePayload()
	if err != nil {
		return nil, err
	}

	cmc := NewChannelContainer()
	cmc.Channel = c
	cmc.IsParticipant = true
	cmc.LastMessage = lastMessageContainer
	cmc.LastMessage.Message = cm
	cmc.LastMessage.Message.ClientRequestId = p.ClientRequestId
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
		p.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE
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

func (p *ChannelRequest) createMessage(channelId int64, typeConstant string) (*ChannelMessage, error) {
	cm := NewChannelMessage()
	cm.Body = getBody(p, typeConstant)
	cm.TypeConstant = typeConstant
	cm.AccountId = p.AccountId
	cm.InitialChannelId = channelId

	err := p.setPayloadWithTypeConstant(cm)
	if err != nil {
		return nil, err
	}

	if err := cm.Create(); err != nil {
		return nil, err
	}

	return cm, nil
}

// setPayloadWithTypeConstant sets the payload of the channel message
// if message type is the system, we dont need to send all payload data to the client
// we just need participants and systemType in the paylaod of the system message
func (p *ChannelRequest) setPayloadWithTypeConstant(cm *ChannelMessage) error {
	if cm.Payload == nil {
		cm.Payload = gorm.Hstore{}
	}

	if cm.TypeConstant == ChannelMessage_TYPE_SYSTEM {
		cm.Payload["systemType"] = p.Payload["systemType"]

		if p.Payload["initialParticipants"] != nil {
			cm.Payload["initialParticipants"] = p.Payload["initialParticipants"]
		}

		if p.Payload["addedBy"] != nil {
			cm.Payload["addedBy"] = p.Payload["addedBy"]
		}

	} else {
		cm.Payload = p.Payload
	}

	return nil
}

func getBody(p *ChannelRequest, typeConstant string) string {
	if typeConstant == ChannelMessage_TYPE_SYSTEM {
		return "system"
	}

	return p.Body
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
