package realtime

import (
	"encoding/json"
	"fmt"
	mongomodels "koding/db/models"
	"socialapi/models"
	"socialapi/request"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

const (
	ChannelUpdateEventName      = "ChannelUpdateHappened"
	RemovedFromChannelEventName = "RemovedFromChannel"
	AddedToChannelEventName     = "AddedToChannel"
)

var mongoAccounts map[int64]*mongomodels.Account

func init() {
	mongoAccounts = make(map[int64]*mongomodels.Account)
}

// Controller holds required instances for processing events
type Controller struct {
	// logging instance
	log logging.Logger

	// connection to RMQ
	rmqConn *amqp.Connection
}

type ParticipantContent struct {
	AccountId    int64  `json:"accountId,string"`
	AccountOldId string `json:"accountOldId"`
	ChannelId    int64  `json:"channelId"`
}

// DefaultErrHandler controls the errors, return false if an error occured
func (r *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	r.log.Error("an error occured deleting realtime event", err)
	delivery.Ack(false)
	return false
}

// New Creates a new controller for realtime package
func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) (*Controller, error) {
	// connnects to RabbitMQ
	rmqConn, err := rmq.Connect("NewRealtimeWorkerController")
	if err != nil {
		return nil, err
	}

	ffc := &Controller{
		log:     log,
		rmqConn: rmqConn.Conn(),
	}

	return ffc, nil
}

// MessageUpdated controls message updated status
// if an error occured , returns error otherwise returns nil
func (f *Controller) MessageUpdated(cm *models.ChannelMessage) error {
	if len(cm.Token) == 0 {
		if err := cm.ById(cm.Id); err != nil {
			return err
		}
	}

	if err := f.sendInstanceEvent(cm.Token, cm, "updateInstance"); err != nil {
		f.log.Error(err.Error())
		return err
	}

	return nil
}

// ChannelParticipantUpdatedEvent is fired when we update any info of the
// channel participant
// We are updating status_constant while removing user from the channel
// but regarding operation has another event, so we are gonna ignore it
func (f *Controller) ChannelParticipantUpdatedEvent(cp *models.ChannelParticipant) error {
	// if status of the participant is left, then ignore the message
	if cp.StatusConstant == models.ChannelParticipant_STATUS_LEFT {
		f.log.Info("Ignoring participant (%d) left channel event", cp.AccountId)
		return nil
	}

	// fetch the channel that user is updated
	c, err := models.ChannelById(cp.ChannelId)
	if err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		Controller:         f,
		Channel:            c,
		EventType:          channelUpdatedEventChannelParticipantUpdated,
		ChannelParticipant: cp,
	}

	return cue.sendForParticipant()
}

// ChannelParticipantRemoved is fired when we remove any info of channel participant
func (f *Controller) ChannelParticipantRemoved(cp *models.ChannelParticipant) error {
	return f.sendChannelParticipantEvent(cp, RemovedFromChannelEventName)
}

// ChannelParticipantAdded is fired when we add any info of channel participant
func (f *Controller) ChannelParticipantAdded(cp *models.ChannelParticipant) error {
	return f.sendChannelParticipantEvent(cp, AddedToChannelEventName)
}

// sendChannelParticipantEvent sends the required info(data) about channel participant
func (f *Controller) sendChannelParticipantEvent(cp *models.ChannelParticipant, eventName string) error {
	c, err := models.ChannelById(cp.ChannelId)
	if err != nil {
		return err
	}

	cc := models.NewChannelContainer()
	err = cc.PopulateWith(*c, cp.AccountId)
	if err != nil {
		return err
	}

	accountOldId, err := models.FetchAccountOldIdByIdFromCache(cp.AccountId)
	if err != nil {
		return err
	}

	pc := &ParticipantContent{
		AccountId:    cp.AccountId,
		AccountOldId: accountOldId,
		ChannelId:    c.Id,
	}

	// send notification to the user(added user)
	if err := f.sendNotification(
		cp.AccountId,
		c.GroupName,
		eventName,
		cc,
	); err != nil {
		f.log.Error("Ignoring err %s ", err.Error())
	}

	// send this event to the channel itself
	return f.publishToChannel(c.Id, eventName, pc)
}

// InteractionSaved runs when interaction is added
func (f *Controller) InteractionSaved(i *models.Interaction) error {
	return f.handleInteractionEvent("InteractionAdded", i)
}

// InteractionSaved runs when interaction is removed
func (f *Controller) InteractionDeleted(i *models.Interaction) error {
	return f.handleInteractionEvent("InteractionRemoved", i)
}

// here inorder to solve overflow
// bug of javascript with int64 values of Go
type InteractionEvent struct {
	MessageId    int64  `json:"messageId,string"`
	AccountId    int64  `json:"accountId,string"`
	AccountOldId string `json:"accountOldId"`
	TypeConstant string `json:"typeConstant"`
	Count        int    `json:"count"`
}

// handleInteractionEvent handle the required info of interaction
func (f *Controller) handleInteractionEvent(eventName string, i *models.Interaction) error {
	q := &request.Query{
		Type:       models.Interaction_TYPE_LIKE,
		ShowExempt: false, // this is default value
	}

	count, err := i.Count(q)
	if err != nil {
		return err
	}

	// fetchs oldId from cache
	oldId, err := models.FetchAccountOldIdByIdFromCache(i.AccountId)
	if err != nil {
		return err
	}

	res := &InteractionEvent{
		MessageId:    i.MessageId,
		AccountId:    i.AccountId,
		AccountOldId: oldId,
		TypeConstant: i.TypeConstant,
		Count:        count,
	}

	m, err := models.ChannelMessageById(i.MessageId)
	if err != nil {
		return err
	}

	err = f.sendInstanceEvent(m.Token, res, eventName)
	if err != nil {
		return err
	}

	return nil
}

// MessageReplySaved updates the channels , send messages in updated channel
// and sends messages which is added
func (f *Controller) MessageReplySaved(mr *models.MessageReply) error {
	f.sendReplyEventAsChannelUpdatedEvent(mr, channelUpdatedEventReplyAdded)
	f.sendReplyAddedEvent(mr)

	return nil
}

func (f *Controller) sendReplyAddedEvent(mr *models.MessageReply) error {
	parent, err := models.ChannelMessageById(mr.MessageId)
	if err != nil {
		return err
	}

	// if reply is created now, it wont be in the cache
	// but fetch it from db and add to cache, we may use it later
	reply, err := models.ChannelMessageById(mr.ReplyId)
	if err != nil {
		return err
	}

	cmc, err := reply.BuildEmptyMessageContainer()
	if err != nil {
		return err
	}

	err = f.sendInstanceEvent(parent.Token, cmc, "ReplyAdded")
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) sendReplyEventAsChannelUpdatedEvent(mr *models.MessageReply, eventType channelUpdatedEventType) error {
	parent, err := models.ChannelMessageById(mr.MessageId)
	if err != nil {
		return err
	}

	// if reply is created now, it wont be in the cache
	// but fetch it from db and add to cache, we may use it later
	reply, err := models.ChannelMessageById(mr.ReplyId)
	if err != nil {
		return err
	}

	cml := models.NewChannelMessageList()
	channels, err := cml.FetchMessageChannels(parent.Id)
	if err != nil {
		return err
	}

	if len(channels) == 0 {
		f.log.Error(
			"Message:(%d) is not in any channel, bu somehow we addd a reply??",
			parent.Id,
		)
		return nil
	}

	cue := &channelUpdatedEvent{
		// channel will be set in range loop
		Controller:           f,
		Channel:              nil,
		ParentChannelMessage: parent,
		ReplyChannelMessage:  reply,
		EventType:            eventType,
	}

	// send this event to all channels
	// that have this message
	for _, channel := range channels {
		cue.Channel = &channel
		err := cue.send()
		if err != nil {
			f.log.Error("err %s", err.Error())
		}
	}

	return nil
}

func (f *Controller) MessageReplyDeleted(mr *models.MessageReply) error {
	f.sendReplyEventAsChannelUpdatedEvent(mr, channelUpdatedEventReplyRemoved)
	m, err := models.ChannelMessageById(mr.MessageId)
	if err != nil {
		return err
	}

	if err := f.sendInstanceEvent(m.Token, mr, "ReplyRemoved"); err != nil {
		return err
	}

	return nil
}

// send message to the channel
func (f *Controller) MessageListSaved(cml *models.ChannelMessageList) error {
	c, err := models.ChannelById(cml.ChannelId)
	if err != nil {
		return err
	}

	// populate cache
	cm, err := models.ChannelMessageById(cml.MessageId)
	if err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		Controller:           f,
		Channel:              c,
		ParentChannelMessage: cm,
		EventType:            channelUpdatedEventMessageAddedToChannel,
	}

	if err := cue.send(); err != nil {
		return err
	}

	if err := f.sendChannelEvent(cml, cm, "MessageAdded"); err != nil {
		return err
	}

	return nil
}

// ChannelMessageListUpdated event states that one of the channel_message_list
// record is updated, it means that one the pinned post's owner glanced it. - At
// least for now - If we decide on another giving another meaning on this event,
// we can rename the event.  PinnedPost's unread count is calculated from the
// last glanced reply's point. This message is user specific. There is no
// relation with channel participants or channel itself
func (f *Controller) ChannelMessageListUpdated(cml *models.ChannelMessageList) error {

	// find the user's pinned post channel
	// we need it for finding the account id
	c, err := models.ChannelById(cml.ChannelId)
	if err != nil {
		return err
	}

	if c.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
		f.log.Error("please investigate here, we have updated the channel message list for a non-pinned post item %+v", c)
		return nil
	}

	// get the glanced message
	cm, err := models.ChannelMessageById(cml.MessageId)
	if err != nil {
		return err
	}

	// No need to fetch the participant from database we are gonna use only the
	// account id
	cp := models.NewChannelParticipant()
	cp.AccountId = c.CreatorId
	cp.ChannelId = c.Id
	if err := cp.FetchParticipant(); err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		// inject controller for reaching to RMQ, log and other stuff
		Controller: f,

		// In which channel this event happened, we need groupName from the
		// channel because user can be in multiple groups, and all group-account
		// couples have separate channels
		Channel: c,

		// We need parentChannelMessage for calculating the unread count of it's replies
		ParentChannelMessage: cm,

		// ChannelParticipant is the reciever of this event
		ChannelParticipant: cp,

		// Assign event type
		EventType: channelUpdatedEventMessageUpdatedAtChannel,
	}

	if err := cue.sendForParticipant(); err != nil {
		return err
	}

	return nil
}

// PinnedChannelListUpdated handles the events of pinned channel lists'.  When a
// user glance a pinned message or when someone posts reply to a message we are
// updating the channel message lists
func (f *Controller) PinnedChannelListUpdated(pclue *models.PinnedChannelListUpdatedEvent) error {
	// find the user's pinned post channel
	// we need it for finding the account id
	c := pclue.Channel

	if &c == nil {
		f.log.Error("channel was nil, discarding the message %+v", pclue)
		return nil
	}

	if c.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
		f.log.Error("please investigate here, we have updated the channel message list for a non-pinned post item %+v", c)
		return nil
	}

	// No need to fetch the participant from database we are gonna use only the
	// account id
	cp := models.NewChannelParticipant()
	cp.AccountId = c.CreatorId
	cp.ChannelId = c.Id
	if err := cp.FetchParticipant(); err != nil {
		return err
	}

	cue := &channelUpdatedEvent{
		// inject controller for reaching to RMQ, log and other stuff
		Controller: f,

		// In which channel this event happened, we need groupName from the
		// channel because user can be in multiple groups, and all group-account
		// couples have separate channels
		Channel: &c,

		// We need parentChannelMessage for calculating the unread count of it's replies
		ParentChannelMessage: &pclue.Message,

		// We need to find out that if the reply is created by a troll
		ReplyChannelMessage: &pclue.Reply,

		// ChannelParticipant is the reciever of this event
		ChannelParticipant: cp,

		// Assign event type
		EventType: channelUpdatedEventReplyAdded,
	}

	if err := cue.sendForParticipant(); err != nil {
		return err
	}

	return nil
}

// todo - refactor this part
func (f *Controller) MessageListDeleted(cml *models.ChannelMessageList) error {
	c, err := models.ChannelById(cml.ChannelId)
	if err != nil {
		return err
	}

	// first try to fetch data from cache
	cm, _ := models.ChannelMessageById(cml.MessageId)
	if cm == nil {
		// if not found, fetch from db by unscoped
		cm = models.NewChannelMessage()
		// When a message is removed, deleted message is not found
		// via regular ById method
		if err := cm.UnscopedById(cml.MessageId); err != nil {
			return err
		}
	}

	cp := models.NewChannelParticipant()
	cp.AccountId = c.CreatorId

	cue := &channelUpdatedEvent{
		Controller:           f,
		Channel:              c,
		ParentChannelMessage: cm,
		ChannelParticipant:   cp,
		EventType:            channelUpdatedEventMessageRemovedFromChannel,
	}

	if err := cue.send(); err != nil {
		return err
	}

	// f.sendNotification(cp.AccountId, ChannelUpdateEventName, cue)

	if err := f.sendChannelEvent(cml, cm, "MessageRemoved"); err != nil {
		return err
	}

	return nil
}

func (f *Controller) sendInstanceEvent(instanceToken string, message interface{}, eventName string) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	routingKey := "oid." + instanceToken + ".event." + eventName
	updateMessage, err := json.Marshal(message)
	if err != nil {
		return err
	}

	updateArr := make([]string, 1)
	if eventName == "updateInstance" {
		updateArr[0] = fmt.Sprintf("{\"$set\":%s}", string(updateMessage))
	} else {
		updateArr[0] = string(updateMessage)
	}

	msg, err := json.Marshal(updateArr)
	if err != nil {
		return err
	}

	f.log.Debug(
		"Sending Instance Event Id:%s Message:%s EventName:%s",
		instanceToken,
		updateMessage,
		eventName,
	)

	return channel.Publish(
		"updateInstances", // exchange name
		routingKey,        // routing key
		false,             // mandatory
		false,             // immediate
		amqp.Publishing{Body: msg}, // message
	)
}

func (f *Controller) sendChannelEvent(cml *models.ChannelMessageList, cm *models.ChannelMessage, eventName string) error {
	cmc, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return err
	}

	return f.publishToChannel(cml.ChannelId, eventName, cmc)
}

// publishToChannel recieves channelId eventName and data to be published
// it fechessecret names from mongo db a publihes to each of them
// message is sent as a json message
// this function is not idempotent
func (f *Controller) publishToChannel(channelId int64, eventName string, data interface{}) error {
	// fetch secret names of the channel
	secretNames, err := models.SecretNamesByChannelId(channelId)
	if err != nil {
		return err
	}

	// if we dont have any secret names, just return
	if len(secretNames) < 1 {
		f.log.Info("Channel %d doest have any secret name", channelId)
		return nil
	}

	//convert data into json message
	byteMessage, err := json.Marshal(data)
	if err != nil {
		return err
	}

	// get a new channel for publishing a message
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	// do not forget to close the channel
	defer channel.Close()

	for _, secretName := range secretNames {
		routingKey := "socialapi.channelsecret." + secretName + "." + eventName

		if err := channel.Publish(
			"broker",   // exchange name
			routingKey, // routing key
			false,      // mandatory
			false,      // immediate
			amqp.Publishing{Body: byteMessage}, // message
		); err != nil {
			return err
		}
	}
	return nil

}

func (f *Controller) sendNotification(
	accountId int64, groupName string, eventName string, data interface{},
) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	account, err := models.FetchAccountFromCache(accountId)
	if err != nil {
		return err
	}

	notification := map[string]interface{}{
		"event":    eventName,
		"context":  groupName,
		"contents": data,
	}

	byteNotification, err := json.Marshal(notification)
	if err != nil {
		return err
	}

	return channel.Publish(
		"notification",
		oldAccount.Profile.Nickname, // this is routing key
		false,
		false,
		amqp.Publishing{Body: byteNotification},
	)
}
