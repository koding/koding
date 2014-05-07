package models

import (
	"errors"
	"fmt"
	"socialapi/config"
	"time"

	"github.com/koding/bongo"
)

type ChannelMessage struct {
	// unique identifier of the channel message
	Id int64 `json:"id"`

	// Body of the mesage
	Body string `json:"body"`

	// Generated Slug for body
	Slug string `json:"slug"                        sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// type of the message
	TypeConstant string `json:"typeConstant"        sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creator of the channel message
	AccountId int64 `json:"accountId"               sql:"NOT NULL"`

	// in which channel this message is created
	InitialChannelId int64 `json:"initialChannelId" sql:"NOT NULL"`

	// Creation date of the message
	CreatedAt time.Time `json:"createdAt"           sql:"DEFAULT:CURRENT_TIMESTAMP"`

	// Modification date of the message
	UpdatedAt time.Time `json:"updatedAt"           sql:"DEFAULT:CURRENT_TIMESTAMP"`

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

func (c *ChannelMessage) AfterDelete() {
	bongo.B.AfterDelete(c)
}

func (c *ChannelMessage) GetId() int64 {
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
	ChannelMessage_TYPE_PRIVATE_MESSAGE = "privateMessage"
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

func (c *ChannelMessage) FetchRelatives(query *Query) (*ChannelMessageContainer, error) {
	if c.Id == 0 {
		return nil, errors.New("Channel message id is not set")
	}
	container := NewChannelMessageContainer()
	container.Message = c

	i := NewInteraction()
	i.MessageId = c.Id

	oldId, err := FetchOldIdByAccountId(c.AccountId)
	if err != nil {
		return nil, err
	}

	container.AccountOldId = oldId

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

	if container.Interactions == nil {
		container.Interactions = make(map[string]*InteractionContainer)
	}
	if _, ok := container.Interactions["like"]; !ok {
		container.Interactions["like"] = NewInteractionContainer()
	}
	container.Interactions["like"] = interactionContainer
	return container, nil
}

// todo include message owner misleads people,
// FetchReplierIds fetches all repliers of a message after a given time.
func (c *ChannelMessage) FetchReplierIds(p *bongo.Pagination, includeMessageOwner bool, t time.Time) ([]int64, error) {
	if c.Id == 0 {
		return nil, errors.New("channel message id is not set")
	}

	// first fetch parent post reply messages
	replyIds, err := c.FetchMessageReplies(p, t, true)
	if err != nil {
		return nil, err
	}

	// add message owner
	if includeMessageOwner {
		replyIds = append(replyIds, c.Id)
	}

	// fetch related channel messages
	messages, err := c.FetchByIds(replyIds)
	if err != nil {
		return nil, err
	}

	// some users can be post more than one time, therefore filter them
	accountIds := fetchDistinctAccounts(messages)

	return accountIds, nil
}

// FetchReplierIdsWithCount fetches all repliers of message with given Id and returns distinct replier count
// Account given with AccountId is excluded from the results
func (c *ChannelMessage) FetchReplierIdsWithCount(p *bongo.Pagination, count *int, t time.Time, lowerTimeLimit bool) ([]int64, error) {
	if c.Id == 0 {
		return nil, errors.New("channel message id is not set")
	}

	// first fetch all replyIds without doing any limitations
	replyIds, err := c.FetchMessageReplies(&bongo.Pagination{}, t, lowerTimeLimit)
	if err != nil {
		return nil, err
	}

	return c.FetchDistinctRepliers(replyIds, p, count)
}

func (c *ChannelMessage) FetchMessageReplies(p *bongo.Pagination, t time.Time, lowerTimeLimit bool) ([]int64, error) {
	if c.Id == 0 {
		return nil, errors.New("channel message id is not set")
	}
	// fetch all replies
	mr := NewMessageReply()
	mr.MessageId = c.Id

	return mr.FetchReplyIds(p, t, lowerTimeLimit)
}

func (c *ChannelMessage) FetchDistinctRepliers(messageReplyIds []int64, p *bongo.Pagination, count *int) ([]int64, error) {
	if len(messageReplyIds) == 0 {
		return nil, errors.New("messageReplyIds length cannot be 0")
	}

	rows, err := bongo.B.DB.Raw("SELECT account_id "+
		"FROM "+c.TableName()+
		" WHERE id IN (?) "+
		"ORDER BY created_at DESC",
		messageReplyIds).Rows()
	if err != nil {
		return nil, err
	}

	defer rows.Close()

	limitReached := false

	replierIds := make([]int64, 0)
	*count = 0

	// replier accounts are retrieved by streaming
	accountMap := map[int64]struct{}{}
	for rows.Next() {
		var accountId int64
		rows.Scan(&accountId)

		// prevent replier duplication
		if _, ok := accountMap[accountId]; !ok && accountId != c.AccountId {
			accountMap[accountId] = struct{}{}
			if !limitReached {
				replierIds = append(replierIds, accountId)
				if len(replierIds) == p.Limit {
					limitReached = true
				}
			}

			*count++
		}
	}

	return replierIds, nil
}

func fetchDistinctAccounts(messages []ChannelMessage) []int64 {
	accountIds := make([]int64, 0)
	if len(messages) == 0 {
		return accountIds
	}

	accountIdMap := map[int64]struct{}{}
	for _, message := range messages {
		accountIdMap[message.AccountId] = struct{}{}
	}

	for key, _ := range accountIdMap {
		accountIds = append(accountIds, key)
	}

	return accountIds
}
