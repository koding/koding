package models

import (
	"encoding/json"
	"fmt"
	"socialapi/config"
	"socialapi/request"
	"strconv"
	"sync"
	"time"

	ve "github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

var mentionRegex = ve.New().
	Find("@").
	BeginCapture().
	Word().
	Maybe("-").
	Maybe(".").
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
	Payload gorm.Hstore `json:"payload"`

	// is required to identify to request in client side
	ClientRequestId string `json:"clientRequestId,omitempty" sql:"-"`
}

const (
	ChannelMessage_TYPE_POST            = "post"
	ChannelMessage_TYPE_REPLY           = "reply"
	ChannelMessage_TYPE_JOIN            = "join"
	ChannelMessage_TYPE_LEAVE           = "leave"
	ChannelMessage_TYPE_PRIVATE_MESSAGE = "privatemessage"
	ChannelMessage_TYPE_BOT             = "bot"
	ChannelMessage_TYPE_SYSTEM          = "system"

	ChannelMessagePayloadKeyLocation = "location"
)

func (c *ChannelMessage) Location() *string {
	return c.GetPayload(ChannelMessagePayloadKeyLocation)
}

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

// Tests are done
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

// Tests are done
func bodyLenCheck(body string) error {
	if len(body) < config.MustGet().Limits.MessageBodyMinLen {
		return fmt.Errorf("message body length should be greater than %d, yours is %d ", config.MustGet().Limits.MessageBodyMinLen, len(body))
	}

	return nil
}

type messageResponseStruct struct {
	Index   int
	Message *ChannelMessageContainer
}

// TODO - remove this function
func (c *ChannelMessage) BuildMessages(query *request.Query, messages []ChannelMessage) ([]*ChannelMessageContainer, error) {
	containers := make([]*ChannelMessageContainer, len(messages))
	if len(containers) == 0 {
		return containers, nil
	}

	var onMessage = make(chan *messageResponseStruct, len(messages))
	var onError = make(chan error, 1)

	var wg sync.WaitGroup

	for i, message := range messages {
		wg.Add(1)

		go func(i int, message ChannelMessage) {
			defer wg.Done()

			d := NewChannelMessage()
			*d = message
			data, err := d.BuildMessage(query)
			if err != nil {
				onError <- err
				return
			}

			onMessage <- &messageResponseStruct{Index: i, Message: data}
		}(i, message)
	}

	wg.Wait()

	for i := 1; i <= len(messages); i++ {
		select {
		case messageResp := <-onMessage:
			containers[messageResp.Index] = messageResp.Message
		case err := <-onError:
			return containers, err
		}
	}

	return containers, nil
}

// TODO - remove this function
func (c *ChannelMessage) BuildMessage(query *request.Query) (*ChannelMessageContainer, error) {
	cmc := NewChannelMessageContainer()
	if err := cmc.Fetch(c.Id, query); err != nil {
		return nil, err
	}

	if cmc.Message == nil {
		return cmc, nil
	}

	var err error
	cmc.Message, err = cmc.Message.PopulatePayload()
	if err != nil {
		return nil, err
	}

	return cmc, nil
}

func (c *ChannelMessage) CheckIsMessageFollowed(query *request.Query) (bool, error) {
	if query.AccountId == 0 {
		return false, nil
	}

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

// Tests are done.
func (c *ChannelMessage) BuildEmptyMessageContainer() (*ChannelMessageContainer, error) {
	if c.Id == 0 {
		return nil, ErrChannelMessageIdIsNotSet
	}
	container := NewChannelMessageContainer()
	container.Message = c

	if c.AccountId == 0 {
		return container, nil
	}

	acc, err := Cache.Account.ById(c.AccountId)
	if err != nil {
		return nil, err
	}

	container.AccountOldId = acc.OldId

	return container, nil
}

func generateMessageListQuery(q *request.Query) *bongo.Query {
	messageType := q.Type
	if messageType == "" {
		messageType = ChannelMessage_TYPE_POST
	}

	query := &bongo.Query{
		Selector: map[string]interface{}{
			"type_constant": messageType,
		},
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
	}

	if q.GroupChannelId != 0 {
		query.Selector["initial_channel_id"] = q.GroupChannelId
	}

	if q.AccountId != 0 {
		query.Selector["account_id"] = q.AccountId
	}

	query.AddScope(ExcludeFields(q.Exclude))
	query.AddScope(StartFrom(q.From))
	query.AddScope(TillTo(q.To))

	return query
}

func (c *ChannelMessage) FetchMessagesByChannelId(channelId int64, q *request.Query) ([]ChannelMessage, error) {
	q.GroupChannelId = channelId
	query := generateMessageListQuery(q)
	query.Sort = map[string]string{
		"created_at": "DESC",
	}

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
	query := generateMessageListQuery(q)

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
		return ErrSlugIsNotSet
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

	query.Type = Channel_TYPE_GROUP
	res, err := c.isInChannel(query, "public")
	if err != nil {
		return err
	}

	if res {
		return nil
	}

	query.Type = Channel_TYPE_ANNOUNCEMENT
	res, err = c.isInChannel(query, "changelog")
	if err != nil {
		return err
	}

	if !res {
		return bongo.RecordNotFound
	}

	return nil
}

func (c *ChannelMessage) isInChannel(query *request.Query, channelName string) (bool, error) {
	if c.Id == 0 {
		return false, ErrChannelMessageIdIsNotSet
	}
	// fetch channel by group name
	query.Name = query.GroupName
	if query.GroupName == "koding" {
		query.Name = channelName
	}

	ch := NewChannel()
	channel, err := ch.ByName(query)
	if err != nil {
		return false, err
	}

	if channel.Id == 0 {
		return false, ErrChannelIsNotSet
	}

	// check if message is in the channel
	cml := NewChannelMessageList()

	return cml.IsInChannel(c.Id, channel.Id)
}

// DeleteMessageDependencies deletes all records from the database that are
// dependencies of a given message. This includes replies, and channel message lists.
func (c *ChannelMessage) DeleteMessageAndDependencies(deleteReplies bool) error {
	if deleteReplies {
		if err := c.DeleteReplies(); err != nil {
			return err
		}
	}

	// delete any associated channel message lists
	if err := c.DeleteChannelMessageLists(); err != nil {
		return err
	}

	err := NewMessageReply().DeleteByOrQuery(c.Id)
	if err != nil {
		return err
	}
	// delete channel message itself
	return c.Delete()
}

// AddReply adds the reply message to db ,
// according to message id
func (c *ChannelMessage) AddReply(reply *ChannelMessage) (*MessageReply, error) {
	if c.Id == 0 {
		return nil, ErrChannelMessageIdIsNotSet
	}
	mr := NewMessageReply()
	mr.MessageId = c.Id
	mr.ReplyId = reply.Id
	mr.CreatedAt = reply.CreatedAt
	if err := mr.Create(); err != nil {
		return nil, err
	}

	return mr, nil
}

//  DeleteReplies deletes all the replies of a given ChannelMessage, one level deep
func (c *ChannelMessage) DeleteReplies() error {
	mr := NewMessageReply()
	mr.MessageId = c.Id

	// list returns ChannelMessage
	messageReplies, err := mr.ListAll()
	if err != nil {
		return err
	}

	// delete message replies
	for _, replyMessage := range messageReplies {
		err := replyMessage.DeleteMessageAndDependencies(false)
		if err != nil {
			return err
		}
	}
	return nil
}

func (c *ChannelMessage) GetChannelMessageLists() ([]ChannelMessageList, error) {
	var listings []ChannelMessageList
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": c.Id,
		},
	}

	if err := NewChannelMessageList().Some(&listings, q); err != nil {
		return nil, err
	}

	return listings, nil
}

func (c *ChannelMessage) DeleteChannelMessageLists() error {
	listings, err := c.GetChannelMessageLists()
	if err != nil {
		return err
	}

	for _, listing := range listings {
		if err := listing.Delete(); err != nil {
			return err
		}
	}

	return nil
}

//  FetchByIds fetchs given ids from database, it doesnt add any meta bits
// properties into query
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

func (c *ChannelMessage) PopulatePayload() (*ChannelMessage, error) {
	cm, err := c.PopulateAddedBy()
	if err != nil {
		return nil, err
	}

	return cm.PopulateInitialParticipants()
}

func (c *ChannelMessage) PopulateAddedBy() (*ChannelMessage, error) {
	newCm := NewChannelMessage()
	*newCm = *c

	addedByData, ok := c.Payload["addedBy"]
	if !ok {
		return c, nil
	}

	addedBy, err := strconv.ParseInt(*addedByData, 10, 64)
	if err != nil {
		return c, err
	}

	a, err := Cache.Account.ById(addedBy)
	if err != nil {
		return c, err
	}

	*addedByData = a.Nick
	newCm.Payload["addedBy"] = addedByData

	return newCm, nil
}

func (c *ChannelMessage) PopulateInitialParticipants() (*ChannelMessage, error) {
	newCm := NewChannelMessage()
	*newCm = *c

	initialParticipants, ok := c.Payload["initialParticipants"]
	if !ok {
		return c, nil
	}

	var participants []string
	err := json.Unmarshal([]byte(*initialParticipants), &participants)
	if err != nil {
		return c, err
	}

	accountIds := make([]string, len(participants))
	for i, participant := range participants {
		accountId, err := strconv.ParseInt(participant, 10, 64)
		if err != nil {
			return c, err
		}

		a, err := Cache.Account.ById(accountId)
		if err != nil {
			return c, err
		}

		accountIds[i] = a.Nick
	}

	participantNicks, err := json.Marshal(accountIds)
	if err != nil {
		return c, err
	}

	pns := string(participantNicks)
	newCm.Payload["initialParticipants"] = &pns

	return newCm, nil
}

// FetchParentChannel fetches the parent channel of the message. When
// initial channel is topic, it fetches the group channel, otherwise
// it just fetches the initial channel as parent.
func (cm *ChannelMessage) FetchParentChannel() (*Channel, error) {
	c, err := Cache.Channel.ById(cm.InitialChannelId)
	if err != nil {
		return nil, err
	}

	if c.TypeConstant != Channel_TYPE_TOPIC {
		return c, nil
	}

	ch, err := Cache.Channel.ByGroupName(c.GroupName)
	if err != nil {
		return nil, err
	}

	return ch, nil
}

func (cm *ChannelMessage) SetPayload(key string, value string) {
	if cm.Payload == nil {
		cm.Payload = gorm.Hstore{}
	}

	cm.Payload[key] = &value
}

func (cm *ChannelMessage) GetPayload(key string) *string {
	if cm.Payload == nil {
		return nil
	}

	val, ok := cm.Payload[key]
	if !ok {
		return nil
	}

	return val
}

// SearchIndexable decides if message is indexable on search engine or not
func (c *ChannelMessage) SearchIndexable() bool {
	return IsIn(c.TypeConstant,
		ChannelMessage_TYPE_POST,
		ChannelMessage_TYPE_REPLY,
		ChannelMessage_TYPE_PRIVATE_MESSAGE,
	)
}
