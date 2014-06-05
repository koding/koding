package models

import (
	"errors"
	"fmt"
	"socialapi/config"
	"time"

	"github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

var mentionRegex = verbalexpressions.New().
	Find("@").
	BeginCapture().
	Word().
	EndCapture().
	Regex()

type ChannelMessage struct {
	// unique identifier of the channel message
	Id int64 `json:"id,string"`

	// Body of the mesage
	Body string `json:"body"`

	// Generated Slug for body
	Slug string `json:"slug"                               sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// type of the message
	TypeConstant string `json:"typeConstant"               sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creator of the channel message
	AccountId int64 `json:"accountId,string"               sql:"NOT NULL"`

	// in which channel this message is created
	InitialChannelId int64 `json:"initialChannelId,string" sql:"NOT NULL"`

	// Creation date of the message
	CreatedAt time.Time `json:"createdAt"                  sql:"DEFAULT:CURRENT_TIMESTAMP"`

	// Modification date of the message
	UpdatedAt time.Time `json:"updatedAt"                  sql:"DEFAULT:CURRENT_TIMESTAMP"`

	// Deletion date of the channel message
	DeletedAt time.Time `json:"deletedAt"`
}

func (c *ChannelMessage) BeforeCreate() {
	c.DeletedAt = ZeroDate()
}

func (c *ChannelMessage) AfterCreate() {
	bongo.B.AfterCreate(c)
}

func (c *ChannelMessage) AfterUpdate() {
	bongo.B.AfterUpdate(c)
}

func (c ChannelMessage) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c ChannelMessage) GetId() int64 {
	return c.Id
}

func (c ChannelMessage) TableName() string {
	return "api.channel_message"
}

const (
	ChannelMessage_TYPE_POST            = "post"
	ChannelMessage_TYPE_REPLY           = "reply"
	ChannelMessage_TYPE_JOIN            = "join"
	ChannelMessage_TYPE_LEAVE           = "leave"
	ChannelMessage_TYPE_CHAT            = "chat"
	ChannelMessage_TYPE_PRIVATE_MESSAGE = "privatemessage"
)

func NewChannelMessage() *ChannelMessage {
	return &ChannelMessage{}
}

func (c *ChannelMessage) ById(id int64) error {
	return bongo.B.ById(c, id)
}

func (c *ChannelMessage) One(q *bongo.Query) error {
	return bongo.B.One(c, c, q)
}

func (c *ChannelMessage) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(c, data, q)
}

func bodyLenCheck(body string) error {
	if len(body) < config.Get().Limits.MessageBodyMinLen {
		return fmt.Errorf("Message Body Length should be greater than %d, yours is %d ", config.Get().Limits.MessageBodyMinLen, len(body))
	}

	return nil
}

// todo create a new message while updating the channel_message and delete other
// cases, since deletion is a soft delete, old instances will still be there
func (c *ChannelMessage) Update() error {
	if err := bodyLenCheck(c.Body); err != nil {
		return err
	}
	// only update body
	err := bongo.B.UpdatePartial(c,
		map[string]interface{}{
			"body": c.Body,
		},
	)
	return err
}

func (c *ChannelMessage) Create() error {
	if err := bodyLenCheck(c.Body); err != nil {
		return err
	}

	var err error
	c, err = Slugify(c)
	if err != nil {
		return err
	}

	return bongo.B.Create(c)
}

func (c *ChannelMessage) Delete() error {
	return bongo.B.Delete(c)
}

func (c *ChannelMessage) FetchByIds(ids []int64) ([]ChannelMessage, error) {
	var messages []ChannelMessage

	if len(ids) == 0 {
		return messages, nil
	}

	if err := bongo.B.FetchByIds(c, &messages, ids); err != nil {
		return nil, err
	}
	return messages, nil
}

func (c *ChannelMessage) BuildMessages(query *Query, messages []ChannelMessage) ([]*ChannelMessageContainer, error) {
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

func (c *ChannelMessage) BuildMessage(query *Query) (*ChannelMessageContainer, error) {
	cmc, err := c.FetchRelatives(query)
	if err != nil {
		return nil, err
	}

	mr := NewMessageReply()
	mr.MessageId = c.Id
	q := query
	q.Limit = 3
	replies, err := mr.List(query)
	if err != nil {
		return nil, err
	}

	repliesCount, err := mr.Count()
	if err != nil {
		return nil, err
	}
	cmc.RepliesCount = repliesCount

	cmc.IsFollowed, err = c.CheckIsMessageFollowed(query)
	if err != nil {
		return nil, err
	}

	populatedChannelMessagesReplies := make([]*ChannelMessageContainer, len(replies))
	for rl := 0; rl < len(replies); rl++ {
		cmrc, err := replies[rl].FetchRelatives(query)
		if err != nil {
			return nil, err
		}
		populatedChannelMessagesReplies[rl] = cmrc
	}

	cmc.Replies = populatedChannelMessagesReplies
	return cmc, nil
}

func (c *ChannelMessage) CheckIsMessageFollowed(query *Query) (bool, error) {
	channel := NewChannel()
	if err := channel.FetchPinnedActivityChannel(query.AccountId, query.GroupName); err != nil {
		if err == gorm.RecordNotFound {
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
		if err == gorm.RecordNotFound {
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

	oldId, err := AccountOldIdById(c.AccountId)
	if err != nil {
		return nil, err
	}

	container.AccountOldId = oldId

	interactionContainer := NewInteractionContainer()
	interactionContainer.ActorsPreview = make([]string, 0)
	interactionContainer.IsInteracted = false
	interactionContainer.ActorsCount = 0

	container.Interactions = make(map[string]*InteractionContainer)
	container.Interactions["like"] = interactionContainer

	return container, nil
}

func (c *ChannelMessage) FetchRelatives(query *Query) (*ChannelMessageContainer, error) {
	container, err := c.BuildEmptyMessageContainer()
	if err != nil {
		return nil, err
	}

	i := NewInteraction()
	i.MessageId = c.Id

	// get preview
	query.Type = "like"
	query.Limit = 3
	interactorIds, err := i.List(query)
	if err != nil {
		return nil, err
	}

	oldIds, err := FetchOldIdsByAccountIds(interactorIds)
	if err != nil {
		return nil, err
	}

	interactionContainer := NewInteractionContainer()
	interactionContainer.ActorsPreview = oldIds

	// check if the current user is interacted in this thread
	isInteracted, err := i.IsInteracted(query.AccountId)
	if err != nil {
		return nil, err
	}

	interactionContainer.IsInteracted = isInteracted

	// fetch interaction count
	count, err := i.Count(query.Type)
	if err != nil {
		return nil, err
	}

	interactionContainer.ActorsCount = count

	container.Interactions["like"] = interactionContainer
	return container, nil
}

func generateMessageListQuery(channelId int64, q *Query) *bongo.Query {
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

func (c *ChannelMessage) FetchMessagesByChannelId(channelId int64, q *Query) ([]ChannelMessage, error) {
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
