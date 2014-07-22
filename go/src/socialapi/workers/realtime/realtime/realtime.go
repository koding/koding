package realtime

import (
	"encoding/json"
	"errors"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/request"
	notificationmodels "socialapi/workers/notification/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
	"labix.org/v2/mgo"
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

// NotificationEvent holds required data for notifcation processing
type NotificationEvent struct {
	// Holds routing key for notification dispatching
	RoutingKey string `json:"routingKey"`

	// Content of the notification
	Content NotificationContent `json:"contents"`
}

// NotificationContent holds required data for notification events
type NotificationContent struct {
	// TypeConstant holds the type of a notification
	// But in some cases, this property can hold the status of the
	// notification, like "delivered" and "read"
	TypeConstant string `json:"type"`

	TargetId int64  `json:"targetId,string"`
	ActorId  string `json:"actorId"`
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

	cmc, err := models.PopulateChannelContainer(*c, cp.AccountId)
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
		cmc,
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

	m := models.NewChannelMessage()
	if err := m.ById(i.MessageId); err != nil {
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
	// fetch a channel
	reply := models.NewChannelMessage()
	if err := reply.ById(mr.ReplyId); err != nil {
		return err
	}

	f.updateAllContainingChannels(mr.MessageId, reply.AccountId)
	f.sendReplyEventAsChannelUpdatedEvent(mr, channelUpdatedEventReplyAdded)
	f.sendReplyAddedEvent(mr)

	return nil
}

func (f *Controller) sendReplyAddedEvent(mr *models.MessageReply) error {
	parent := models.NewChannelMessage()
	if err := parent.ById(mr.MessageId); err != nil {
		return err
	}

	reply := models.NewChannelMessage()
	if err := reply.ById(mr.ReplyId); err != nil {
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
	parent, err := mr.FetchParent()
	if err != nil {
		return err
	}

	reply, err := mr.FetchReply()
	if err != nil {
		return err
	}

	cml := models.NewChannelMessageList()
	channels, err := cml.FetchMessageChannels(parent.Id)
	if err != nil {
		return err
	}

	if len(channels) == 0 {
		f.log.Info("Message:(%d) is not in any channel", parent.Id)
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

	for _, channel := range channels {
		if channel.TypeConstant == models.Channel_TYPE_TOPIC {
			f.log.Critical("skip topic channels")
			continue
		}
		cue.Channel = &channel
		// send this event to all channels
		// that have this message
		err := cue.send()
		if err != nil {
			f.log.Error("err %s", err.Error())
		}
	}

	return nil
}

func (f *Controller) MessageReplyDeleted(mr *models.MessageReply) error {

	f.sendReplyEventAsChannelUpdatedEvent(mr, channelUpdatedEventReplyRemoved)

	m := models.NewChannelMessage()
	if err := m.ById(mr.MessageId); err != nil {
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

	cm := models.NewChannelMessage()
	if err := cm.ById(cml.MessageId); err != nil {
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

	if err := f.sendChannelEvent(cml, "MessageAdded"); err != nil {
		return err
	}

	return nil
}

func (f *Controller) MessageListUpdated(cml *models.ChannelMessageList) error {
	c, err := models.ChannelById(cml.ChannelId)
	if err != nil {
		return err
	}

	cm := models.NewChannelMessage()
	if err := cm.ById(cml.MessageId); err != nil {
		return err
	}

	cp := models.NewChannelParticipant()
	cp.AccountId = c.CreatorId

	cue := &channelUpdatedEvent{
		Controller:           f,
		Channel:              c,
		ParentChannelMessage: cm,
		ChannelParticipant:   cp,
		EventType:            channelUpdatedEventMessageUpdatedAtChannel,
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

	cm := models.NewChannelMessage()
	if err := cm.ById(cml.MessageId); err != nil {
		return err
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

	if err := f.sendChannelEvent(cml, "MessageRemoved"); err != nil {
		return err
	}

	return nil
}

func (f *Controller) NotifyUser(notification *notificationmodels.Notification) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return errors.New("channel connection error")
	}
	defer channel.Close()

	activity, nc, err := notification.FetchLastActivity()
	if err != nil {
		return err
	}

	// do not notify actor for her own action
	if activity.ActorId == notification.AccountId {
		return nil
	}

	// do not notify user when notification is not yet activated,
	// or it is already glanced (subscription case)
	if notification.ActivatedAt.IsZero() || notification.Glanced {
		return nil
	}

	oldAccount, err := fetchOldAccount(notification.AccountId)
	if err != nil {
		f.log.Warning("an error occurred while fetching old account: %s", err)
		return nil
	}

	// fetch user profile name from bongo as routing key
	ne := &NotificationEvent{}

	ne.Content = NotificationContent{
		TargetId:     nc.TargetId,
		TypeConstant: nc.TypeConstant,
	}
	ne.Content.ActorId, _ = models.FetchAccountOldIdByIdFromCache(activity.ActorId)

	notificationMessage, err := json.Marshal(ne)
	if err != nil {
		return err
	}

	routingKey := oldAccount.Profile.Nickname

	err = channel.Publish(
		"notification",
		routingKey,
		false,
		false,
		amqp.Publishing{Body: notificationMessage},
	)
	if err != nil {
		return fmt.Errorf("an error occurred while notifying user: %s", err)
	}

	return nil
}

// to-do add eviction here
func fetchOldAccountFromCache(accountId int64) (*mongomodels.Account, error) {
	if account, ok := mongoAccounts[accountId]; ok {
		return account, nil
	}

	account, err := fetchOldAccount(accountId)
	if err != nil {
		return nil, err
	}

	mongoAccounts[accountId] = account
	return account, nil
}

// fetchOldAccount fetches mongo account of a given new account id.
// this function must be used under another file for further use
func fetchOldAccount(accountId int64) (*mongomodels.Account, error) {
	newAccount := models.NewAccount()
	if err := newAccount.ById(accountId); err != nil {
		return nil, err
	}

	account, err := modelhelper.GetAccountById(newAccount.OldId)
	if err != nil {
		if err == mgo.ErrNotFound {
			return nil, errors.New("old account not found")
		}

		return nil, err
	}

	return account, nil
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

func (f *Controller) sendChannelEvent(cml *models.ChannelMessageList, eventName string) error {
	cm := models.NewChannelMessage()
	if err := cm.ById(cml.MessageId); err != nil {
		return err
	}

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
	secretNames, err := fetchSecretNames(channelId)
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

func fetchSecretNames(channelId int64) ([]string, error) {
	names := make([]string, 0)
	c, err := models.ChannelById(channelId)
	if err != nil {
		return names, err
	}

	name := fmt.Sprintf(
		"socialapi-group-%s-type-%s-name-%s",
		c.GroupName,
		c.TypeConstant,
		c.Name,
	)

	names, err = modelhelper.FetchFlattenedSecretName(name)
	return names, nil
}

func (f *Controller) sendNotification(
	accountId int64, groupName string, eventName string, data interface{},
) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	oldAccount, err := fetchOldAccountFromCache(accountId)
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

// updateAllContainingChannels fetch all channels that parent is in and
// updates those channels except the user who did the action.
//
// TODO: move this to own worker, realtime worker shouldn't touch db
func (f *Controller) updateAllContainingChannels(parentId int64, excludedId int64) error {
	cml := models.NewChannelMessageList()
	channels, err := cml.FetchMessageChannels(parentId)
	if err != nil {
		return err
	}

	if len(channels) == 0 {
		return nil
	}

	for _, channel := range channels {
		// if channel type is group, we dont need to update group's updatedAt
		if channel.TypeConstant == models.Channel_TYPE_GROUP {
			continue
		}

		// excludedId refers to users who did the action
		if channel.CreatorId == excludedId {
			cml, err := channel.FetchMessageList(parentId)
			if err != nil {
				f.log.Error("error fetching message list for", parentId, err)
				continue
			}

			// `Glance` for author, so on next new message, unread count is right
			err = cml.Glance()
			if err != nil {
				f.log.Error("error glancing for messagelist", parentId, err)
				continue
			}

			// no need to tell user they did an action
			continue
		}

		// pinned activity channel holds messages one by one
		if channel.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
			channel.UpdatedAt = time.Now().UTC()
			if err := channel.Update(); err != nil {
				f.log.Error("channel update failed", err)
			}
			continue
		}

		// if channel.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		err := models.NewChannelMessageList().UpdateAddedAt(channel.Id, parentId)
		if err != nil {
			f.log.Error("message list update failed", err)
		}
		//}
	}

	return nil
}
