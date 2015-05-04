package models

import (
	"fmt"
	"strings"
	"time"

	"socialapi/request"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

type Channel struct {
	// unique identifier of the channel
	Id int64 `json:"id,string"`

	// Token holds the uuid for interoperability with the bongo-client
	Token string `json:"token"`

	// Name of the channel
	Name string `json:"name"                         sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Creator of the channel
	CreatorId int64 `json:"creatorId,string"         sql:"NOT NULL"`

	// Name of the group which channel is belong to
	GroupName string `json:"groupName"               sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Purpose of the channel
	Purpose string `json:"purpose"`

	// Type of the channel
	TypeConstant string `json:"typeConstant"         sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Privacy constant of the channel
	PrivacyConstant string `json:"privacyConstant"   sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// MetaBits holds meta bit information about the channel
	MetaBits MetaBits `json:"metaBits"`

	// Extra data storage
	Payload gorm.Hstore `json:"payload"`

	// Creation date of the channel
	CreatedAt time.Time `json:"createdAt"            sql:"NOT NULL"`

	// Modification date of the channel
	UpdatedAt time.Time `json:"updatedAt"            sql:"NOT NULL"`

	// Deletion date of the channel
	DeletedAt time.Time `json:"deletedAt"`
}

// to-do check for allowed channels
const (
	ChannelLinkedPrefix = "linked"
	// TYPES
	Channel_TYPE_GROUP           = "group"
	Channel_TYPE_ANNOUNCEMENT    = "announcement"
	Channel_TYPE_TOPIC           = "topic"
	Channel_TYPE_LINKED_TOPIC    = ChannelLinkedPrefix + Channel_TYPE_TOPIC
	Channel_TYPE_FOLLOWINGFEED   = "followingfeed"
	Channel_TYPE_FOLLOWERS       = "followers"
	Channel_TYPE_PINNED_ACTIVITY = "pinnedactivity"
	Channel_TYPE_PRIVATE_MESSAGE = "privatemessage"
	Channel_TYPE_COLLABORATION   = "collaboration"
	Channel_TYPE_BOT             = "bot"
	Channel_TYPE_DEFAULT         = "default"
	// Privacy
	Channel_PRIVACY_PUBLIC  = "public"
	Channel_PRIVACY_PRIVATE = "private"
	// Koding Group Name
	Channel_KODING_NAME = "koding"
)

// NewChannel inits channel
// fills required constants what necessary is as default
//
// Tests are done
func NewChannel() *Channel {
	return &Channel{
		Name:            "channel-" + RandomName(),
		GroupName:       Channel_KODING_NAME,
		TypeConstant:    Channel_TYPE_DEFAULT,
		PrivacyConstant: Channel_PRIVACY_PRIVATE,
	}
}

// NewPrivateMessageChannel takes the creator id and group name of the channel as arguments
// sets required content of the channel
// and sets constants as 'private'
//
// Tests are done
func NewPrivateMessageChannel(creatorId int64, groupName string) *Channel {
	return NewPrivateChannel(creatorId, groupName, Channel_TYPE_PRIVATE_MESSAGE)
}

// NewCollaborationChannel takes the creator id and group name of the channel as arguments
// sets required content of the channel
// and sets constants as 'private'
//
// Tests are done
func NewCollaborationChannel(creatorId int64, groupName string) *Channel {
	return NewPrivateChannel(creatorId, groupName, Channel_TYPE_COLLABORATION)
}

// NewPrivateChannel takes the creator id, group name of the channel and channel type as arguments
// sets required content of the channel
// and sets constants as 'private'
//
// Tests are done
func NewPrivateChannel(creatorId int64, groupName string, typeConstant string) *Channel {
	c := NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.Name = RandomName()
	c.TypeConstant = typeConstant
	c.PrivacyConstant = Channel_PRIVACY_PRIVATE
	c.Purpose = ""
	return c
}

// Create creates a channel in db
// some fields of the channel must be filled (should not be empty)
//
// Tests are done..
func (c *Channel) Create() error {
	if c.Name == "" || c.GroupName == "" || c.TypeConstant == "" || c.CreatorId == 0 {
		return fmt.Errorf("Validation failed %s - %s - %s - %d", c.Name, c.GroupName, c.TypeConstant, c.CreatorId)
	}

	// golang returns -1 if item not in the string
	if strings.Index(c.Name, " ") > -1 {
		return fmt.Errorf("Channel name %q has empty space in it", c.Name)
	}

	// if channel type is not group or following try to create it
	if c.TypeConstant != Channel_TYPE_GROUP && c.TypeConstant != Channel_TYPE_FOLLOWERS {
		return bongo.B.Create(c)
	}

	// selectors helps database to create what we need
	var selector map[string]interface{}

	switch c.TypeConstant {
	case Channel_TYPE_GROUP:
		selector = map[string]interface{}{
			"group_name":    c.GroupName,
			"type_constant": c.TypeConstant,
		}
	case Channel_TYPE_DEFAULT:
		selector = map[string]interface{}{
			"group_name":    c.GroupName,
			"type_constant": c.TypeConstant,
		}
	case Channel_TYPE_FOLLOWERS:
		selector = map[string]interface{}{
			"creator_id":    c.CreatorId,
			"type_constant": c.TypeConstant,
		}
	}

	// if err is nil
	// it means we already have that channel
	err := c.One(bongo.NewQS(selector))
	if err == nil {
		// this means, we already have the channel in the db, it is safe to return
		return nil
	}

	// if error is not NotFound, return it
	if err != bongo.RecordNotFound {
		return err
	}

	// if we couldnt find the record in the db, then create it
	return bongo.B.Create(c)
}

func (c *Channel) CreateRaw() error {
	insertSql := "INSERT INTO " +
		c.BongoName() +
		` ("name","creator_id","group_name","purpose","type_constant",` +
		`"privacy_constant", "created_at", "updated_at", "deleted_at")` +
		"VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) " +
		"RETURNING ID"

	return bongo.B.DB.CommonDB().QueryRow(insertSql, c.Name, c.CreatorId,
		c.GroupName, c.Purpose, c.TypeConstant, c.PrivacyConstant,
		c.CreatedAt, c.UpdatedAt, c.DeletedAt).Scan(&c.Id)
}

// AddParticipant adds a user(participant) to the channel
// if account is already in the channel,
// it won't add again user to channel as participant
//
// Tests are done.
func (c *Channel) AddParticipant(participantId int64) (*ChannelParticipant, error) {
	if c.Id == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	if c.CreatorId == 0 {
		return nil, ErrCreatorIdIsNotSet
	}

	// only the creator can be added as participant to the channel
	if c.TypeConstant == Channel_TYPE_PINNED_ACTIVITY {
		if c.CreatorId != participantId {
			return nil, ErrCannotAddNewParticipantToPinnedChannel
		}
	}

	// do not add users to the linked channels
	if c.TypeConstant == Channel_TYPE_LINKED_TOPIC {
		return nil, ErrChannelIsLinked
	}

	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = participantId

	// get participant from db if it is created before
	err := cp.FetchParticipant()
	// supress not found error
	if err != nil && err != bongo.RecordNotFound {
		return nil, err
	}

	// if we have this record in DB
	if cp.Id != 0 {
		// if the user is already actively participant of a channel
		// return it early
		if cp.StatusConstant == ChannelParticipant_STATUS_ACTIVE {
			// TODO, why we are returning an error here?
			return nil, ErrAccountIsAlreadyInTheChannel
		}

		cp.StatusConstant = ChannelParticipant_STATUS_ACTIVE
		if err := cp.Update(); err != nil {
			return nil, err
		}

		return cp, nil
	}

	cp.StatusConstant = ChannelParticipant_STATUS_ACTIVE

	if err := cp.Create(); err != nil {
		return nil, err
	}

	return cp, nil
}

// RemoveParticipant removes the user(participant) from the channel
// if user is already removed from the channel, don't need to do anything
//
// Tests are done.
func (c *Channel) RemoveParticipant(participantIds ...int64) error {
	return c.removeParticipation(ChannelParticipant_STATUS_LEFT, participantIds...)
}

// BlockParticipant blocks the user(participant) from reaching to a channel
func (c *Channel) BlockParticipant(participantIds ...int64) error {
	return c.removeParticipation(ChannelParticipant_STATUS_BLOCKED, participantIds...)
}

func (c *Channel) removeParticipation(typeConstant string, participantIds ...int64) error {
	if c.Id == 0 {
		return ErrChannelIdIsNotSet
	}

	for _, participantId := range participantIds {
		cp := NewChannelParticipant()
		cp.ChannelId = c.Id
		cp.AccountId = participantId

		err := cp.FetchParticipant()
		// if user is not in this channel, do nothing
		if err == bongo.RecordNotFound {
			continue
		}

		if err != nil {
			return err
		}

		if cp.StatusConstant == typeConstant {
			continue
		}

		// if status of the participant is left or blocked (participant is not in
		// the channel), do nothing
		if cp.StatusConstant == ChannelParticipant_STATUS_BLOCKED &&
			typeConstant == ChannelParticipant_STATUS_LEFT {
			continue
		}

		cp.StatusConstant = typeConstant
		if err := cp.Update(); err != nil {
			return err
		}
	}

	return nil
}

// FetchParticipantIds gives ID of the accounts which ids are active in the channel
func (c *Channel) FetchParticipantIds(q *request.Query) ([]int64, error) {
	var participantIds []int64

	if c.Id == 0 {
		return participantIds, ErrChannelIdIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id":      c.Id,
			"status_constant": ChannelParticipant_STATUS_ACTIVE,
		},
		Pluck: "account_id",
	}

	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

	cp := NewChannelParticipant()
	err := cp.Some(&participantIds, query)
	if err != nil {
		return nil, err
	}

	return participantIds, nil
}

func (c *Channel) FetchParticipants(q *request.Query) ([]Account, error) {
	var accounts []Account
	ids, err := c.FetchParticipantIds(q)
	if err != nil {
		return accounts, err
	}

	return NewAccount().FetchByIds(ids)
}

// AddMessage adds given message to the channel, if the message is already in the
// channel, it doesn't add again, this method is idempotent
// you can call many times, but message will be in the channel list once
//
// has full test suit
func (c *Channel) AddMessage(cm *ChannelMessage) (*ChannelMessageList, error) {
	if c.Id == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	if cm.Id == 0 {
		return nil, ErrMessageIdIsNotSet
	}

	cml, err := c.FetchMessageList(cm.Id)
	if err == nil {
		return nil, ErrMessageAlreadyInTheChannel
	}

	// silence record not found err
	if err != bongo.RecordNotFound {
		return nil, err
	}

	cml.ChannelId = c.Id
	cml.MessageId = cm.Id
	cml.ClientRequestId = cm.ClientRequestId

	if err := cml.Create(); err != nil {
		if IsUniqueConstraintError(err) {
			return nil, ErrMessageAlreadyInTheChannel
		}

		return nil, err
	}

	return cml, nil
}

func (c *Channel) EnsureMessage(cm *ChannelMessage, force bool) (*ChannelMessageList, error) {
	cml := NewChannelMessageList()
	err := bongo.B.DB.Model(cml).Unscoped().Where("channel_id = ? and message_id = ?", c.Id, cm.Id).First(cml).Error

	if err == bongo.RecordNotFound {
		return c.AddMessage(cm)
	}

	if err != nil {
		return nil, err
	}

	if !force {
		return cml, nil
	}

	if cml.DeletedAt != ZeroDate() {
		cml.DeletedAt = ZeroDate()
	}

	err = bongo.B.DB.Unscoped().Model(cml).Save(cml).Error
	if err != nil {
		return nil, err
	}

	_, err = c.AddMessage(cm)
	if err == ErrMessageAlreadyInTheChannel {
		return cml, nil
	}

	if err != nil {
		return nil, err
	}

	return cml, nil
}

// RemoveMessage removes the message from the channel
// if message is already removed from the channel, it will not remove again  when we try to remove it
//
// Tests are done.
//
// TODO do not return channelmessagelist from delete function !!
func (c *Channel) RemoveMessage(messageId int64) (*ChannelMessageList, error) {
	if c.Id == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	if messageId == 0 {
		return nil, ErrMessageIdIsNotSet
	}

	cml, err := c.FetchMessageList(messageId)
	if err != nil {
		return nil, err
	}

	if err := cml.Delete(); err != nil {
		return nil, err
	}

	return cml, nil
}

// FetchMessageList fetchs the messages in the channel
//
// has full test suit
func (c *Channel) FetchMessageList(messageId int64) (*ChannelMessageList, error) {
	if c.Id == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	if messageId == 0 {
		return nil, ErrMessageIdIsNotSet
	}

	cml := NewChannelMessageList()
	selector := map[string]interface{}{
		"channel_id": c.Id,
		"message_id": messageId,
	}

	return cml, cml.One(bongo.NewQS(selector))
}

// FetchChannelIdByNameAndGroupName fetchs the first ID of the channel via channel name & group name
//
// Tests are done..
func (c *Channel) FetchChannelIdByNameAndGroupName(name, groupName string) (int64, error) {
	if name == "" {
		return 0, ErrNameIsNotSet
	}

	if groupName == "" {
		return 0, ErrGroupNameIsNotSet
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"name":       name,
			"group_name": groupName,
		},
		Pagination: *bongo.NewPagination(1, 0),
		Pluck:      "id",
	}
	var ids []int64
	if err := c.Some(&ids, query); err != nil {
		return 0, err
	}

	if ids == nil {
		return 0, bongo.RecordNotFound
	}

	if len(ids) == 0 {
		return 0, bongo.RecordNotFound
	}

	return ids[0], nil
}

func (c *Channel) Search(q *request.Query) ([]Channel, error) {
	if q.GroupName == "" {
		return nil, ErrGroupNameIsNotSet
	}

	if q.Type == "" {
		q.Type = Channel_TYPE_TOPIC
	}

	var channels []Channel

	bongoQuery := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name":       q.GroupName,
			"type_constant":    q.Type,
			"privacy_constant": Channel_PRIVACY_PUBLIC,
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	// this will hide moderation needed channels
	bongoQuery.AddScope(RemoveModerationNeededContent(c, false))

	bongoQuery.AddScope(RemoveTrollContent(c, q.ShowExempt))

	query := bongo.B.BuildQuery(c, bongoQuery)

	// use 'ilike' for case-insensitive search
	query = query.Where("name ilike ?", "%"+q.Name+"%")

	if err := bongo.CheckErr(
		query.Find(&channels),
	); err != nil {
		return nil, err
	}

	if channels == nil {
		return make([]Channel, 0), nil
	}

	return channels, nil
}

// ByName fetches the channel by name, type_constant and group_name, it doesnt
// have the best name, but evolved to this situation :/
func (c *Channel) ByName(q *request.Query) (Channel, error) {
	var channel Channel

	if q.GroupName == "" {
		return channel, ErrGroupNameIsNotSet
	}

	if q.Type == "" {
		q.Type = Channel_TYPE_TOPIC
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name":    q.GroupName,
			"type_constant": q.Type,
			"name":          q.Name,
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

	err := c.One(query)
	if err != nil && err != bongo.RecordNotFound {
		return channel, err
	}

	// try to fetch it's root
	if err == bongo.RecordNotFound {
		query.Selector["type_constant"] = ChannelLinkedPrefix + q.Type
		if err := c.One(query); err != nil {
			return channel, err
		}

		if root, err := c.FetchRoot(); err != nil {
			return channel, err
		} else {
			return channel, ErrChannelIsLeafFunc(root.Name, root.TypeConstant)
		}
	}

	return *c, nil
}

func (c *Channel) List(q *request.Query) ([]Channel, error) {
	if q.GroupName == "" {
		return nil, ErrGroupNameIsNotSet
	}

	var channels []Channel

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name": q.GroupName,
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	if q.Type != "" {
		query.Selector["type_constant"] = q.Type
	}

	// this will hide moderation needed channels
	query.AddScope(RemoveModerationNeededContent(c, false))
	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

	err := c.Some(&channels, query)
	if err != nil {
		return nil, err
	}

	if channels == nil {
		return make([]Channel, 0), nil
	}

	return channels, nil
}

// FetchLastMessage fetch the last message of the channel from DB
// sorts the messages, then fetch the message which added last
//
// Tests are done.
func (c *Channel) FetchLastMessage() (*ChannelMessage, error) {
	if c.Id == 0 {
		return nil, ErrChannelIdIsNotSet
	}

	messageId, err := c.FetchLastMessageId()
	if err != nil && err != bongo.RecordNotFound {
		return nil, err
	}

	if err == bongo.RecordNotFound {
		return nil, nil
	}

	cm := NewChannelMessage()
	if err := cm.ById(messageId); err != nil {
		return nil, err
	}

	return cm.PopulatePayload()
}

func (c *Channel) FetchLastMessageId() (int64, error) {
	if c.Id == 0 {
		return 0, ErrChannelIdIsNotSet
	}

	cml := NewChannelMessageList()
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": c.Id,
		},
		Sort: map[string]string{
			"added_at": "DESC",
		},
		Pagination: *bongo.NewPagination(1, 0),
		Pluck:      "message_id",
	}

	var messageIds []int64
	err := cml.Some(&messageIds, query)
	if err != nil {
		return 0, err
	}

	if messageIds == nil || len(messageIds) == 0 {
		return 0, bongo.RecordNotFound
	}

	return messageIds[0], nil
}

// FetchPinnedActivityChannel fetch the channel within required fields
func (c *Channel) FetchPinnedActivityChannel(accountId int64, groupName string) error {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"creator_id":    accountId,
			"group_name":    groupName,
			"type_constant": Channel_TYPE_PINNED_ACTIVITY,
		},
	}

	return c.One(query)
}

func EnsurePinnedActivityChannel(accountId int64, groupName string) (*Channel, error) {
	c := NewChannel()
	err := c.FetchPinnedActivityChannel(accountId, groupName)

	// if we find the channel
	// return early
	if err == nil {
		return c, nil
	}

	// silence not found error
	if err != bongo.RecordNotFound {
		return nil, err
	}

	c.Name = RandomName()
	c.CreatorId = accountId
	c.GroupName = groupName
	c.TypeConstant = Channel_TYPE_PINNED_ACTIVITY
	c.PrivacyConstant = Channel_PRIVACY_PRIVATE
	if err := c.Create(); err != nil {
		return nil, err
	}

	// after creating pinned channel
	// add user a participant
	// todo add test for this case
	_, err = c.AddParticipant(accountId)
	if err != nil {
		return nil, err
	}

	return c, nil
}

// CanOpen checks permissions for channels
// group channels can be opened by everyone
// But private message channel just CanOpened by participant
//
// Tests are done.
func (c *Channel) CanOpen(accountId int64) (bool, error) {
	if c.Id == 0 {
		return false, ErrChannelIdIsNotSet
	}

	if c.CreatorId == 0 {
		return false, ErrCreatorIdIsNotSet
	}

	// see only your pinned posts
	if c.TypeConstant == Channel_TYPE_PINNED_ACTIVITY {
		if c.CreatorId == accountId {
			return true, nil
		}

		return false, nil
	}

	// check if user is a participant
	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	isParticipant, err := cp.IsParticipant(accountId)
	if err != nil {
		return false, err
	}

	// if already participant, return success
	if isParticipant {
		return true, nil
	}

	// special cases for koding group
	if c.GroupName == Channel_KODING_NAME {
		// anyone can read group activity
		if c.TypeConstant == Channel_TYPE_GROUP {
			return true, nil
		}

		// anyone can read announcement activity
		if c.TypeConstant == Channel_TYPE_ANNOUNCEMENT {
			return true, nil
		}

		// anyone can read topic feed
		// this is here for non-participated topic channels
		if c.TypeConstant == Channel_TYPE_TOPIC {
			return true, nil
		}
	}

	return false, nil
}

func (c *Channel) MarkIfExempt() error {
	isExempt, err := c.isExempt()
	if err != nil {
		return err
	}

	if isExempt {
		c.MetaBits.Mark(Troll)
	}

	return nil
}

func (c *Channel) isExempt() (bool, error) {
	// return early if channel is already exempt
	if c.MetaBits.Is(Troll) {
		return true, nil
	}

	accountId, err := c.getAccountId()
	if err != nil {
		return false, err
	}

	account, err := ResetAccountCache(accountId)
	if err != nil {
		return false, err
	}

	if account.IsTroll {
		return true, nil
	}

	return false, nil
}

// getAccountId checks the channel that has a creator id or not
// and returns id of creator of the channel
//
// Tests are done
func (c *Channel) getAccountId() (int64, error) {
	if c.CreatorId != 0 {
		return c.CreatorId, nil
	}

	if c.Id == 0 {
		return 0, ErrChannelIdIsNotSet
	}

	cn := NewChannel()
	if err := cn.ById(c.Id); err != nil {
		return 0, err
	}

	return cn.CreatorId, nil

}

// FetchParticipant simply fetch the participants from the channel
// if participant leaves from the channel
// just marking status constant as LEFT
//
// Tests are done
func (c *Channel) FetchParticipant(accountId int64) (*ChannelParticipant, error) {
	if c.Id == 0 {
		return nil, ErrIdIsNotSet
	}

	if accountId == 0 {
		return nil, ErrAccountIdIsNotSet
	}

	cp := NewChannelParticipant()
	cp.AccountId = accountId
	cp.ChannelId = c.Id
	if err := cp.FetchParticipant(); err != nil {
		return nil, err
	}

	return cp, nil
}

// IsParticipant controls that the participant is in the channel or not
//
// Tests are done.
func (c *Channel) IsParticipant(accountId int64) (bool, error) {
	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	return cp.IsParticipant(accountId)
}

func (c *Channel) FetchPublicChannel(groupName string) error {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"group_name":    groupName,
			"type_constant": Channel_TYPE_GROUP,
		},
	}

	err := c.One(query)
	if err == bongo.RecordNotFound {
		return ErrGroupNotFound
	}

	return err
}

func isMessageCrossIndexed(messageId int64) (error, bool) {
	count, err := NewChannelMessageList().CountWithQuery(&bongo.Query{
		Selector: map[string]interface{}{
			"message_id": messageId,
		},
	})
	if err != nil {
		return err, false
	}
	return nil, count > 0
}

func (c *Channel) deleteChannelMessages(messageMap map[int64]struct{}) error {
	messageIds := make([]int64, 0)

	for messageId, _ := range messageMap {
		messageIds = append(messageIds, messageId)
	}

	messages, err := NewChannelMessage().FetchByIds(messageIds)
	if err != nil {
		return err
	}

	for _, message := range messages {
		err, isCrossIndexed := isMessageCrossIndexed(message.Id)
		if err != nil {
			return err
		}

		if isCrossIndexed {
			continue
		}

		if err = message.Delete(); err != nil {
			return err
		}
	}

	return nil
}

func getListingBatch(channelId int64, c int) ([]ChannelMessageList, error) {
	var listings []ChannelMessageList
	q := &bongo.Query{
		Selector: map[string]interface{}{"channel_id": channelId},
		Pagination: bongo.Pagination{
			Skip:  100 * c,
			Limit: 100,
		}}
	if err := NewChannelMessageList().Some(&listings, q); err != nil {
		return nil, err
	}
	return listings, nil
}

// deleteChannelLists deletes all channel lists with given channel id
// and returns dangling channel message id map
func (c *Channel) deleteChannelLists() (map[int64]struct{}, error) {
	messageMap := make(map[int64]struct{})
	for i := 0; ; i++ {
		listings, err := getListingBatch(c.Id, i)
		if err != nil {
			return messageMap, err
		}

		for _, listing := range listings {
			messageMap[listing.MessageId] = struct{}{}
			if err := listing.Delete(); err != nil {
				return messageMap, err
			}
		}
		if len(listings) < 100 {
			return messageMap, nil
		}
	}
}

// FetchRoot fetches the root of a channel if linked
func (c *Channel) FetchRoot() (*Channel, error) {
	cl := NewChannelLink()
	cl.LeafId = c.Id
	return cl.FetchRoot()
}

// FetchLeaves fetches the leaves of a channel if linked
func (c *Channel) FetchLeaves() ([]Channel, error) {
	cl := NewChannelLink()
	cl.RootId = c.Id
	return cl.List(request.NewQuery())
}

func (c *Channel) ShowUnreadCount() bool {
	return c.TypeConstant == Channel_TYPE_PINNED_ACTIVITY ||
		c.TypeConstant == Channel_TYPE_PRIVATE_MESSAGE ||
		c.TypeConstant == Channel_TYPE_COLLABORATION ||
		c.TypeConstant == Channel_TYPE_ANNOUNCEMENT ||
		c.TypeConstant == Channel_TYPE_TOPIC ||
		c.TypeConstant == Channel_TYPE_BOT
}
