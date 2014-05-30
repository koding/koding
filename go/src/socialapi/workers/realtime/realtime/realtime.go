package realtime

import (
	"encoding/json"
	"errors"
	"fmt"
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
	"strconv"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
	"labix.org/v2/mgo"
)

var mongoAccounts map[int64]*mongomodels.Account

func init() {
	mongoAccounts = make(map[int64]*mongomodels.Account)
}

type Action func(*Controller, []byte) error

type Controller struct {
	routes  map[string]Action
	log     logging.Logger
	rmqConn *amqp.Connection
}

type NotificationEvent struct {
	RoutingKey string              `json:"routingKey"`
	Content    NotificationContent `json:"contents"`
}

type NotificationContent struct {
	TypeConstant string `json:"type"`
	TargetId     int64  `json:"targetId,string"`
	ActorId      string `json:"actorId"`
}

func (r *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	r.log.Error("an error occured deleting realtime event", err)
	delivery.Ack(false)
	return false
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) (*Controller, error) {
	rmqConn, err := rmq.Connect("NewRealtimeWorkerController")
	if err != nil {
		return nil, err
	}

	ffc := &Controller{
		log:     log,
		rmqConn: rmqConn.Conn(),
	}

	routes := map[string]Action{
		"api.channel_message_created": (*Controller).MessageSaved,
		"api.channel_message_updated": (*Controller).MessageUpdated,
		"api.channel_message_deleted": (*Controller).MessageDeleted,

		"api.interaction_created": (*Controller).InteractionSaved,
		"api.interaction_deleted": (*Controller).InteractionDeleted,

		"api.message_reply_created": (*Controller).MessageReplySaved,
		"api.message_reply_deleted": (*Controller).MessageReplyDeleted,

		"api.channel_message_list_created": (*Controller).MessageListSaved,
		"api.channel_message_list_updated": (*Controller).MessageListUpdated,
		"api.channel_message_list_deleted": (*Controller).MessageListDeleted,

		"api.channel_participant_created": (*Controller).ChannelParticipantEvent,
		"api.channel_participant_updated": (*Controller).ChannelParticipantEvent,
		"api.channel_participant_deleted": (*Controller).ChannelParticipantEvent,

		"notification.notification_created": (*Controller).NotifyUser,
		"notification.notification_updated": (*Controller).NotifyUser,
	}

	ffc.routes = routes

	return ffc, nil
}

func (f *Controller) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Received %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return handler(f, data)
}

// no operation for message save for now
func (f *Controller) MessageSaved(data []byte) error {
	return nil
}

// no operation for message delete for now
// channel_message_delete will handle message deletions from the
func (f *Controller) MessageDeleted(data []byte) error {
	return nil
}

func (f *Controller) MessageUpdated(data []byte) error {
	cm, err := helper.MapToChannelMessage(data)
	if err != nil {
		return err
	}

	err = f.sendInstanceEvent(cm.GetId(), cm, "updateInstance")
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

func (f *Controller) ChannelParticipantEvent(data []byte) error {
	cp := models.NewChannelParticipant()
	if err := json.Unmarshal(data, cp); err != nil {
		return err
	}

	c, err := models.ChannelById(cp.ChannelId)
	if err != nil {
		return err
	}

	cmc, err := models.PopulateChannelContainer(*c, cp.AccountId)
	if err != nil {
		return err
	}

	if cp.StatusConstant == models.ChannelParticipant_STATUS_ACTIVE {
		err = f.sendNotification(cp.AccountId, "AddedToChannel", cmc)
	} else if cp.StatusConstant == models.ChannelParticipant_STATUS_LEFT {
		err = f.sendNotification(cp.AccountId, "RemovedFromChannel", cmc)
	} else {
		err = fmt.Errorf("Unhandled event type for channel participation %s", cp.StatusConstant)
	}

	if err != nil {
		f.log.Error("Ignoring err %s ", err.Error())
	}

	return nil
}

func (f *Controller) handleChannelParticipantEvent(eventName string, data []byte) error {
	cp := models.NewChannelParticipant()
	if err := json.Unmarshal(data, cp); err != nil {
		return err
	}

	c, err := models.ChannelById(cp.ChannelId)
	if err != nil {
		return err
	}

	return f.sendNotification(cp.AccountId, eventName, c)
}

func (f *Controller) InteractionSaved(data []byte) error {
	return f.handleInteractionEvent("InteractionAdded", data)
}

func (f *Controller) InteractionDeleted(data []byte) error {
	return f.handleInteractionEvent("InteractionRemoved", data)
}

func (f *Controller) handleInteractionEvent(eventName string, data []byte) error {
	i, err := helper.MapToInteraction(data)
	if err != nil {
		return err
	}

	count, err := i.Count(i.TypeConstant)
	if err != nil {
		return err
	}

	oldId, err := models.AccountOldIdById(i.AccountId)
	if err != nil {
		return err
	}

	res := map[string]interface{}{
		"messageId":    i.MessageId,
		"accountId":    i.AccountId,
		"accountOldId": oldId,
		"typeConstant": i.TypeConstant,
		"count":        count,
	}

	err = f.sendInstanceEvent(i.MessageId, res, eventName)
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

func (f *Controller) MessageReplySaved(data []byte) error {
	mr, err := helper.MapToMessageReply(data)
	if err != nil {
		return err
	}

	f.sendReplyAddedEventAsNotificationEvent(mr)
	f.sendReplyAddedEvent(mr)
	return nil
}

func (f *Controller) sendReplyAddedEvent(mr *models.MessageReply) error {
	reply := models.NewChannelMessage()
	if err := reply.ById(mr.ReplyId); err != nil {
		return err
	}

	cmc, err := reply.BuildEmptyMessageContainer()
	if err != nil {
		return err
	}

	err = f.sendInstanceEvent(mr.MessageId, cmc, "ReplyAdded")
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

func (f *Controller) MessageReplyDeleted(data []byte) error {
	i, err := helper.MapToMessageReply(data)
	if err != nil {
		return err
	}

	err = f.sendInstanceEvent(i.MessageId, i, "ReplyRemoved")
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

// send message to the channel
func (f *Controller) MessageListSaved(data []byte) error {
	cml, err := helper.MapToChannelMessageList(data)
	if err != nil {
		return err
	}

	err = f.sendChannelEvent(cml, "MessageAdded")
	if err != nil {
		return err
	}

	return nil
}

// no operation for channel_message_list_updated event
func (f *Controller) MessageListUpdated(data []byte) error {
	return nil
}

func (f *Controller) MessageListDeleted(data []byte) error {
	cml, err := helper.MapToChannelMessageList(data)
	if err != nil {
		return err
	}

	err = f.sendChannelEvent(cml, "MessageRemoved")
	if err != nil {
		return err
	}
	return nil
}

func (f *Controller) NotifyUser(data []byte) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return errors.New("channel connection error")
	}
	defer channel.Close()

	notification := notificationmodels.NewNotification()
	if err := notification.MapMessage(data); err != nil {
		return err
	}

	activity, nc, err := notification.FetchLastActivity()
	if err != nil {
		return err
	}

	// do not notify actor for her own action
	if activity.ActorId == notification.AccountId {
		return nil
	}

	// do not notify user when notification is not yet activated
	if notification.ActivatedAt.IsZero() {
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
	ne.Content.ActorId, _ = models.AccountOldIdById(activity.ActorId)

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

func (f *Controller) sendInstanceEvent(instanceId int64, message interface{}, eventName string) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	id := strconv.FormatInt(instanceId, 10)
	routingKey := "oid." + id + ".event." + eventName

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

	f.log.Debug("Sending Instance Event Id:%s Message:%s ", id, updateMessage)

	return channel.Publish(
		"updateInstances", // exchange name
		routingKey,        // routing key
		false,             // mandatory
		false,             // immediate
		amqp.Publishing{Body: msg}, // message
	)
}

func (f *Controller) sendChannelEvent(cml *models.ChannelMessageList, eventName string) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	secretNames, err := fetchSecretNames(cml.ChannelId)
	if err != nil {
		return err
	}

	// if we dont have any secret names, just return
	if len(secretNames) < 1 {
		f.log.Info("Channel %d doest have any secret name", cml.ChannelId)
		return nil
	}

	cm := models.NewChannelMessage()
	if err := cm.ById(cml.MessageId); err != nil {
		return err
	}

	cmc, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return err
	}

	byteMessage, err := json.Marshal(cmc)
	if err != nil {
		return err
	}

	f.log.Debug("Sending Channel Event ChannelId:%d Message:%s ", cml.ChannelId, byteMessage)

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

func (f *Controller) sendNotification(accountId int64, eventName string, data interface{}) error {
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
