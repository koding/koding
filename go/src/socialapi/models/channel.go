package models

import (
	"errors"
	"fmt"
	"socialapi/request"
	"strings"
	"time"

	"github.com/koding/bongo"
)

type Channel struct {
	// unique identifier of the channel
	Id int64 `json:"id,string"`

	// Name of the channel
	Name string `json:"name"                         sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Creator of the channel
	CreatorId int64 `json:"creatorId,string"         sql:"NOT NULL"`

	// Name of the group which channel is belong to
	GroupName string `json:"groupName"               sql:"NOT NULL;TYPE:VARCHAR(200);"`

	// Purpose of the channel
	Purpose string `json:"purpose"`

	// Secret key of the channel for event propagation purposes
	// we can put this key into another table?
	SecretKey string `json:"-"`

	// Type of the channel
	TypeConstant string `json:"typeConstant"         sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Privacy constant of the channel
	PrivacyConstant string `json:"privacyConstant"   sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// MetaBits holds meta bit information about the channel
	MetaBits MetaBits `json:"metaBits"`

	// Creation date of the channel
	CreatedAt time.Time `json:"createdAt"            sql:"NOT NULL"`

	// Modification date of the channel
	UpdatedAt time.Time `json:"updatedAt"            sql:"NOT NULL"`

	// Deletion date of the channel
	DeletedAt time.Time `json:"deletedAt"`
}

// to-do check for allowed channels
const (
	// TYPES
	Channel_TYPE_GROUP           = "group"
	Channel_TYPE_TOPIC           = "topic"
	Channel_TYPE_FOLLOWINGFEED   = "followingfeed"
	Channel_TYPE_FOLLOWERS       = "followers"
	Channel_TYPE_CHAT            = "chat"
	Channel_TYPE_PINNED_ACTIVITY = "pinnedactivity"
	Channel_TYPE_PRIVATE_MESSAGE = "privatemessage"
	Channel_TYPE_DEFAULT         = "default"
	// Privacy
	Channel_PRIVACY_PUBLIC  = "public"
	Channel_PRIVACY_PRIVATE = "private"
	// Koding Group Name
	Channel_KODING_NAME = "koding"
)

func NewChannel() *Channel {
	return &Channel{
		Name:            "Channel" + RandomName(),
		CreatorId:       0,
		GroupName:       Channel_KODING_NAME,
		Purpose:         "",
		SecretKey:       "",
		TypeConstant:    Channel_TYPE_DEFAULT,
		PrivacyConstant: Channel_PRIVACY_PRIVATE,
	}
}

func NewPrivateMessageChannel(creatorId int64, groupName string) *Channel {
	c := NewChannel()
	c.GroupName = groupName
	c.CreatorId = creatorId
	c.Name = RandomName()
	c.TypeConstant = Channel_TYPE_PRIVATE_MESSAGE
	c.PrivacyConstant = Channel_PRIVACY_PRIVATE
	c.Purpose = ""
	return c
}

func (c *Channel) BeforeCreate() error {
	c.CreatedAt = time.Now().UTC()
	c.UpdatedAt = time.Now().UTC()
	c.DeletedAt = ZeroDate()

	return c.MarkIfExempt()
}

func (c *Channel) BeforeUpdate() error {
	c.UpdatedAt = time.Now()

	return c.MarkIfExempt()
}

func (c Channel) GetId() int64 {
	return c.Id
}

func (c Channel) TableName() string {
	return "api.channel"
}

func (c *Channel) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *Channel) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c Channel) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *Channel) Update() error {
	if c.Name == "" || c.GroupName == "" {
		return fmt.Errorf("Validation failed %s - %s", c.Name, c.GroupName)
	}

	return bongo.B.Update(c)
}

func (c *Channel) Create() error {
	if c.Name == "" || c.GroupName == "" || c.TypeConstant == "" {
		return fmt.Errorf("Validation failed %s - %s -%s", c.Name, c.GroupName, c.TypeConstant)
	}

	// golang returns -1 if item not in the string
	if strings.Index(c.Name, " ") > -1 {
		return fmt.Errorf("Channel name %q has empty space in it", c.Name)
	}

	if c.TypeConstant == Channel_TYPE_GROUP ||
		c.TypeConstant == Channel_TYPE_FOLLOWERS /* we can add more types here */ {

		var selector map[string]interface{}
		switch c.TypeConstant {
		case Channel_TYPE_GROUP:
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
			return nil
			// return fmt.Errorf("%s typed channel is already created before for %s group", c.TypeConstant, c.GroupName)
		}

		if err != bongo.RecordNotFound {
			return err
		}

	}

	return bongo.B.Create(c)
}

func (c *Channel) CreateRaw() error {
	insertSql := "INSERT INTO " +
		c.TableName() +
		` ("name","creator_id","group_name","purpose","secret_key","type_constant",` +
		`"privacy_constant", "created_at", "updated_at", "deleted_at")` +
		"VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) " +
		"RETURNING ID"

	return bongo.B.DB.CommonDB().QueryRow(insertSql, c.Name, c.CreatorId,
		c.GroupName, c.Purpose, c.SecretKey, c.TypeConstant, c.PrivacyConstant,
		c.CreatedAt, c.UpdatedAt, c.DeletedAt).Scan(&c.Id)
}

func (c *Channel) Delete() error {
	return bongo.B.Delete(c)
}

func (c *Channel) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *Channel) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *Channel) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

func (c *Channel) FetchByIds(ids []int64) ([]Channel, error) {
	var channels []Channel

	if len(ids) == 0 {
		return channels, nil
	}

	if err := bongo.B.FetchByIds(c, &channels, ids); err != nil {
		return nil, err
	}
	return channels, nil
}

func (c *Channel) AddParticipant(participantId int64) (*ChannelParticipant, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel Id is not set")
	}

	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = participantId

	err := cp.FetchParticipant()
	if err != nil && err != bongo.RecordNotFound {
		return nil, err
	}

	// if we have this record in DB
	if cp.Id != 0 {
		// if status is not active
		if cp.StatusConstant == ChannelParticipant_STATUS_ACTIVE {
			return nil, errors.New(fmt.Sprintf("Account %d is already a participant of channel %d", cp.AccountId, cp.ChannelId))
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

func (c *Channel) RemoveParticipant(participantId int64) error {
	if c.Id == 0 {
		return errors.New("Channel Id is not set")
	}

	cp := NewChannelParticipant()
	cp.ChannelId = c.Id
	cp.AccountId = participantId

	err := cp.FetchParticipant()
	// if user is not in this channel, do nothing
	if err == bongo.RecordNotFound {
		return nil
	}

	if err != nil {
		return err
	}

	if cp.StatusConstant == ChannelParticipant_STATUS_LEFT {
		return nil
	}

	cp.StatusConstant = ChannelParticipant_STATUS_LEFT
	if err := cp.Update(); err != nil {
		return err
	}

	return nil
}

func (c *Channel) FetchParticipantIds(q *request.Query) ([]int64, error) {
	var participantIds []int64

	if c.Id == 0 {
		return participantIds, errors.New("Channel Id is not set")
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

func (c *Channel) AddMessage(messageId int64) (*ChannelMessageList, error) {
	cml, err := c.FetchMessageList(messageId)
	if err == nil {
		return nil, errors.New("Message is already in the channel")
	}

	// silence record not found err
	if err != bongo.RecordNotFound {
		return nil, err
	}

	cml.ChannelId = c.Id
	cml.MessageId = messageId

	if err := cml.Create(); err != nil {
		return nil, err
	}

	return cml, nil
}

func (c *Channel) RemoveMessage(messageId int64) (*ChannelMessageList, error) {
	cml, err := c.FetchMessageList(messageId)
	if err != nil {
		return nil, err
	}

	if err := cml.Delete(); err != nil {
		return nil, err
	}

	return cml, nil
}

func (c *Channel) FetchMessageList(messageId int64) (*ChannelMessageList, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel Id is not set")
	}

	cml := NewChannelMessageList()
	selector := map[string]interface{}{
		"channel_id": c.Id,
		"message_id": messageId,
	}

	return cml, cml.One(bongo.NewQS(selector))
}

func (c *Channel) FetchChannelIdByNameAndGroupName(name, groupName string) (int64, error) {
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
		return nil, fmt.Errorf("Query doesnt have any Group info %+v", q)
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

	bongoQuery.AddScope(RemoveTrollContent(c, q.ShowExempt))

	query := bongo.B.BuildQuery(c, bongoQuery)
	query = query.Where("name like ?", q.Name+"%")

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

func (c *Channel) ByName(q *request.Query) (Channel, error) {
	var channel Channel

	if q.GroupName == "" {
		return channel, fmt.Errorf("Query doesnt have any Group info %+v", q)
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

	if err := c.One(query); err != nil {
		return channel, err
	}

	return *c, nil
}

func (c *Channel) List(q *request.Query) ([]Channel, error) {
	if q.GroupName == "" {
		return nil, fmt.Errorf("Query doesnt have any Group info %+v", q)
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

func (c *Channel) FetchLastMessage() (*ChannelMessage, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel Id is not set")
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
		return nil, err
	}

	if messageIds == nil || len(messageIds) == 0 {
		return nil, nil
	}

	cm := NewChannelMessage()
	if err := cm.ById(messageIds[0]); err != nil {
		return nil, err
	}

	return cm, nil
}

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

func (c *Channel) CanOpen(accountId int64) (bool, error) {
	if c.Id == 0 {
		return false, errors.New("channel id is not set")
	}

	if accountId == 0 {
		return false, errors.New("accountId is not set")
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

	// anyone can read group activity
	if c.TypeConstant == Channel_TYPE_GROUP {
		return true, nil
	}

	// anyone can read topic feed
	// this is here for non-participated topic channels
	if c.TypeConstant == Channel_TYPE_TOPIC {
		return true, nil
	}

	// see only your pinned posts
	// user should be added as a participant to pinned post
	if c.TypeConstant == Channel_TYPE_PINNED_ACTIVITY {
		return false, nil
	}

	// see only your private messages
	// user should be added as a participant to private message
	if c.TypeConstant == Channel_TYPE_PRIVATE_MESSAGE {
		return false, nil
	}

	return false, nil
}

func (c *Channel) MarkIfExempt() error {
	isExempt, err := c.isExempt()
	if err != nil {
		return err
	}

	if isExempt {
		c.MetaBits.MarkTroll()
	}

	return nil
}

func (c *Channel) isExempt() (bool, error) {
	// return early if channel is already exempt
	if c.MetaBits.IsTroll() {
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

func (c *Channel) getAccountId() (int64, error) {
	if c.CreatorId != 0 {
		return c.CreatorId, nil
	}

	if c.Id == 0 {
		return 0, fmt.Errorf("couldnt find accountId from content %+v", c)
	}

	cn := NewChannel()
	if err := cn.ById(c.Id); err != nil {
		return 0, err
	}

	return cn.CreatorId, nil

}
