package models

import (
	"errors"
	"fmt"
	"socialapi/config"
	"socialapi/request"
	"time"

	ve "github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

var mentionRegex = ve.New().
	Find("@").
	BeginCapture().
	Word().
	EndCapture().
	Regex()

type ChannelMessage struct {
	// unique identifier of the channel message
	Id int64 `json:"id,string"`

	// Token holds the uuid for interoperability with the bongo-client
	Token string `json:"token"`

	// Body of the mesage
	Body string `json:"body"`

	// Generated Slug for body
	Slug string `json:"slug"                               sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// type of the m essage
	TypeConstant string `json:"typeConstant"               sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creator of the channel message
	AccountId int64 `json:"accountId,string"               sql:"NOT NULL"`

	// in which channel this message is created
	InitialChannelId int64 `json:"initialChannelId,string" sql:"NOT NULL"`

	// holds troll, unsafe, etc
	MetaBits MetaBits `json:"metaBits"`

	// Creation date of the message
	CreatedAt time.Time `json:"createdAt"                  sql:"DEFAULT:CURRENT_TIMESTAMP"`

	// Modification date of the message
	UpdatedAt time.Time `json:"updatedAt"                  sql:"DEFAULT:CURRENT_TIMESTAMP"`

	// Deletion date of the channel message
	DeletedAt time.Time `json:"deletedAt"`

	// Extra data storage
	Payload gorm.Hstore `json:"payload,omitempty"`

	// is required to identify to request in client side
	RequestData string `json:"requestData,omitempty" sql:"-"`
}

const (
	ChannelMessage_TYPE_POST            = "post"
	ChannelMessage_TYPE_REPLY           = "reply"
	ChannelMessage_TYPE_JOIN            = "join"
	ChannelMessage_TYPE_LEAVE           = "leave"
	ChannelMessage_TYPE_PRIVATE_MESSAGE = "privatemessage"
)

func (c *ChannelMessage) MarkIfExempt() error {
	isExempt, err := c.isExempt()
	if err != nil {
		return err
	}

	if isExempt {
		c.MetaBits.Mark(Troll)
	}

	return nil
}

func (c *ChannelMessage) isExempt() (bool, error) {
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

	if account == nil {
		return false, fmt.Errorf("account is nil, accountId:%d", c.AccountId)
	}

	if account.IsTroll {
		return true, nil
	}

	return false, nil
}

func (c *ChannelMessage) getAccountId() (int64, error) {
	if c.AccountId != 0 {
		return c.AccountId, nil
	}

	if c.Id == 0 {
		return 0, fmt.Errorf("couldnt find accountId from content %+v", c)
	}

	cm := NewChannelMessage()
	if err := cm.ById(c.Id); err != nil {
		return 0, err
	}

	return cm.AccountId, nil
}

func bodyLenCheck(body string) error {
	if len(body) < config.MustGet().Limits.MessageBodyMinLen {
		return fmt.Errorf("message body length should be greater than %d, yours is %d ", config.MustGet().Limits.MessageBodyMinLen, len(body))
	}

	return nil
}

// todo create a new message while updating the channel_message and delete other
// cases, since deletion is a soft delete, old instances will still be there

// CreateRaw creates a new channel message without effected by auto generated createdAt
// and updatedAt values
func (c *ChannelMessage) CreateRaw() error {
	insertSql := "INSERT INTO " +
		c.TableName() +
		` ("body","slug","type_constant","account_id","initial_channel_id",` +
		`"created_at","updated_at","deleted_at","payload") ` +
		"VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) " +
		"RETURNING ID"

	return bongo.B.DB.CommonDB().QueryRow(insertSql, c.Body, c.Slug, c.TypeConstant, c.AccountId, c.InitialChannelId,
		c.CreatedAt, c.UpdatedAt, c.DeletedAt, c.Payload).Scan(&c.Id)
}

// UpdateBodyRaw updates message body without effecting createdAt/UpdatedAt
// timestamps
func (c *ChannelMessage) UpdateBodyRaw() error {
	updateSql := fmt.Sprintf("UPDATE %s SET body=? WHERE id=?", c.TableName())

	return bongo.B.DB.Exec(updateSql, c.Body, c.Id).Error
}

// TODO - remove this function
func (c *ChannelMessage) BuildMessages(query *request.Query, messages []ChannelMessage) ([]*ChannelMessageContainer, error) {
	containers := make([]*ChannelMessageContainer, len(messages))
	if len(containers) == 0 {
		return containers, nil
	}

	for i, message := range messages {
		d := NewChannelMessage()
		*d = message
		data, err := d.BuildMessage(query)
		if err != nil {
			return containers, err
		}
		containers[i] = data
	}

	return containers, nil
}

// TODO - remove this function
func (c *ChannelMessage) BuildMessage(query *request.Query) (*ChannelMessageContainer, error) {
	cmc := NewChannelMessageContainer()
	if err := cmc.Fetch(c.Id, query); err != nil {
		return nil, err
	}

	return cmc, cmc.AddIsFollowed(query).AddIsInteracted(query).Err
}

func (c *ChannelMessage) CheckIsMessageFollowed(query *request.Query) (bool, error) {
	channel := NewChannel()
	if err := channel.FetchPinnedActivityChannel(query.AccountId, query.GroupName); err != nil {
		if err == bongo.RecordNotFound {
			return false, nil
		}
		return false, err
	}

	cml := NewChannelMessageList()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": channel.Id,
			"message_id": c.Id,
		},
	}
	if err := cml.One(q); err != nil {
		if err == bongo.RecordNotFound {
			return false, nil
		}

		return false, err
	}

	return true, nil
}

func (c *ChannelMessage) BuildEmptyMessageContainer() (*ChannelMessageContainer, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel message id is not set")
	}
	container := NewChannelMessageContainer()
	container.Message = c

	oldId, err := FetchAccountOldIdByIdFromCache(c.AccountId)
	if err != nil {
		return nil, err
	}

	container.AccountOldId = oldId

	return container, nil
}

func generateMessageListQuery(channelId int64, q *request.Query) *bongo.Query {
	messageType := q.Type
	if messageType == "" {
		messageType = ChannelMessage_TYPE_POST
	}

	return &bongo.Query{
		Selector: map[string]interface{}{
			"account_id":         q.AccountId,
			"initial_channel_id": channelId,
			"type_constant":      messageType,
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
		Sort: map[string]string{
			"created_at": "DESC",
		},
	}
}

func (c *ChannelMessage) FetchMessagesByChannelId(channelId int64, q *request.Query) ([]ChannelMessage, error) {
	query := generateMessageListQuery(channelId, q)

	var messages []ChannelMessage
	if err := c.Some(&messages, query); err != nil {
		return nil, err
	}

	if messages == nil {
		return make([]ChannelMessage, 0), nil
	}
	return messages, nil
}

func (c *ChannelMessage) GetMentionedUsernames() []string {
	flattened := make([]string, 0)

	res := mentionRegex.FindAllStringSubmatch(c.Body, -1)
	if len(res) == 0 {
		return flattened
	}

	participants := map[string]struct{}{}
	// remove duplicate mentions
	for _, ele := range res {
		participants[ele[1]] = struct{}{}
	}

	for participant := range participants {
		flattened = append(flattened, participant)
	}

	return flattened
}

// FetchTotalMessageCount fetch the count of all messages in the channel
func (c *ChannelMessage) FetchTotalMessageCount(q *request.Query) (int, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id":    q.AccountId,
			"type_constant": q.Type,
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	query.AddScope(RemoveTrollContent(
		c, q.ShowExempt,
	))

	return c.CountWithQuery(query)
}

// FetchMessageIds fetch id of the messages in the channel
// sorts the messages by descending order
func (c *ChannelMessage) FetchMessageIds(q *request.Query) ([]int64, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id":    q.AccountId,
			"type_constant": q.Type,
		},
		Pluck:      "id",
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
		Sort: map[string]string{
			"created_at": "DESC",
		},
	}

	query.AddScope(RemoveTrollContent(c, q.ShowExempt))

	var messageIds []int64
	if err := c.Some(&messageIds, query); err != nil {
		return nil, err
	}

	if messageIds == nil {
		return make([]int64, 0), nil
	}

	return messageIds, nil
}

// BySlug fetchs channel message by its slug
// checks if message is in the channel or not
func (c *ChannelMessage) BySlug(query *request.Query) error {
	if query.Slug == "" {
		return errors.New("slug is not set")
	}

	// fetch message itself
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"slug": query.Slug,
		},
	}

	q.AddScope(RemoveTrollContent(
		c, query.ShowExempt,
	))

	if err := c.One(q); err != nil {
		return err
	}

	// fetch channel by group name
	query.Name = query.GroupName
	query.Type = Channel_TYPE_GROUP
	ch := NewChannel()
	channel, err := ch.ByName(query)
	if err != nil {
		return err
	}

	if channel.Id == 0 {
		return errors.New("channel is not found")
	}

	// check if message is in the channel
	cml := NewChannelMessageList()
	res, err := cml.IsInChannel(c.Id, channel.Id)
	if err != nil {
		return err
	}

	// if message is not in the channel
	if !res {
		return bongo.RecordNotFound
	}

	return nil
}
