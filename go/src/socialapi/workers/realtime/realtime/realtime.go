package realtime

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"strconv"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/koding/worker"

	"github.com/streadway/amqp"
)

type Action func(*RealtimeWorkerController, []byte) error

type RealtimeWorkerController struct {
	routes  map[string]Action
	log     logging.Logger
	rmqConn *amqp.Connection
}

func (r *RealtimeWorkerController) DefaultErrHandler(delivery amqp.Delivery, err error) {
	r.log.Error("an error occured putting message back to queue", err)
	// multiple false
	// reque true
	delivery.Nack(false, true)
}

func NewRealtimeWorkerController(rmq *rabbitmq.RabbitMQ, log logging.Logger) (*RealtimeWorkerController, error) {
	rmqConn, err := rmq.Connect("NewRealtimeWorkerController")
	if err != nil {
		return nil, err
	}

	ffc := &RealtimeWorkerController{
		log:     log,
		rmqConn: rmqConn.Conn(),
	}

	routes := map[string]Action{
		"api.channel_message_created": (*RealtimeWorkerController).MessageSaved,
		"api.channel_message_updated": (*RealtimeWorkerController).MessageUpdated,
		"api.channel_message_deleted": (*RealtimeWorkerController).MessageDeleted,

		"api.interaction_created": (*RealtimeWorkerController).InteractionSaved,
		"api.interaction_deleted": (*RealtimeWorkerController).InteractionDeleted,

		"api.message_reply_created": (*RealtimeWorkerController).MessageReplySaved,
		"api.message_reply_deleted": (*RealtimeWorkerController).MessageReplyDeleted,

		"api.channel_message_list_created": (*RealtimeWorkerController).MessageListSaved,
		"api.channel_message_list_updated": (*RealtimeWorkerController).MessageListUpdated,
		"api.channel_message_list_deleted": (*RealtimeWorkerController).MessageListDeleted,

		"api.channel_participant_created": (*RealtimeWorkerController).ChannelParticipantAdded,
		"api.channel_participant_deleted": (*RealtimeWorkerController).ChannelParticipantRemoved,
	}

	ffc.routes = routes

	return ffc, nil
}

func (f *RealtimeWorkerController) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Received %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	return handler(f, data)
}

func mapMessageToChannelMessage(data []byte) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func mapMessageToChannelMessageList(data []byte) (*models.ChannelMessageList, error) {
	cm := models.NewChannelMessageList()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func mapMessageToInteraction(data []byte) (*models.Interaction, error) {
	i := models.NewInteraction()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}

func mapMessageToMessageReply(data []byte) (*models.MessageReply, error) {
	i := models.NewMessageReply()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}

// no operation for message save for now
func (f *RealtimeWorkerController) MessageSaved(data []byte) error {
	return nil
}

// no operation for message delete for now
// channel_message_delete will handle message deletions from the
func (f *RealtimeWorkerController) MessageDeleted(data []byte) error {
	return nil
}

func (f *RealtimeWorkerController) MessageUpdated(data []byte) error {
	cm, err := mapMessageToChannelMessage(data)
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

func (f *RealtimeWorkerController) ChannelParticipantAdded(data []byte) error {
	return f.handleChannelParticipantEvent("AddedToChannel", data)
}

func (f *RealtimeWorkerController) ChannelParticipantRemoved(data []byte) error {
	return f.handleChannelParticipantEvent("RemovedFromChannel", data)
}

func (f *RealtimeWorkerController) handleChannelParticipantEvent(eventName string, data []byte) error {
	cp := models.NewChannelParticipant()
	if err := json.Unmarshal(data, cp); err != nil {
		return err
	}

	c := models.NewChannel()
	if err := c.ById(cp.ChannelId); err != nil {
		return err
	}
	return f.sendNotification(cp.AccountId, eventName, c)
}

func (f *RealtimeWorkerController) InteractionSaved(data []byte) error {
	return f.handleInteractionEvent("InteractionAdded", data)
}

func (f *RealtimeWorkerController) InteractionDeleted(data []byte) error {
	return f.handleInteractionEvent("InteractionRemoved", data)
}

func (f *RealtimeWorkerController) handleInteractionEvent(eventName string, data []byte) error {
	i, err := mapMessageToInteraction(data)
	if err != nil {
		return err
	}

	count, err := i.Count(i.TypeConstant)
	if err != nil {
		return err
	}

	res := map[string]interface{}{
		"messageId":    i.MessageId,
		"accountId":    i.AccountId,
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

func (f *RealtimeWorkerController) MessageReplySaved(data []byte) error {
	i, err := mapMessageToMessageReply(data)
	if err != nil {
		return err
	}

	reply := models.NewChannelMessage()
	if err := reply.ById(i.ReplyId); err != nil {
		return err
	}

	err = f.sendInstanceEvent(i.MessageId, reply, "ReplyAdded")
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

func (f *RealtimeWorkerController) MessageReplyDeleted(data []byte) error {
	i, err := mapMessageToMessageReply(data)
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
func (f *RealtimeWorkerController) MessageListSaved(data []byte) error {
	cml, err := mapMessageToChannelMessageList(data)
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
func (f *RealtimeWorkerController) MessageListUpdated(data []byte) error {
	return nil
}

func (f *RealtimeWorkerController) MessageListDeleted(data []byte) error {
	cml, err := mapMessageToChannelMessageList(data)
	if err != nil {
		return err
	}

	err = f.sendChannelEvent(cml, "MessageRemoved")
	if err != nil {
		return err
	}
	return nil
}

func (f *RealtimeWorkerController) sendInstanceEvent(instanceId int64, message interface{}, eventName string) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	routingKey := "oid." + strconv.FormatInt(instanceId, 10) + ".event." + eventName

	updateMessage, err := json.Marshal(message)
	if err != nil {
		return err
	}

	updateArr := make([]string, 1)
	if eventName == "updateInstances" {
		updateArr[0] = fmt.Sprintf("{\"$set\":%s}", string(updateMessage))
	} else {
		updateArr[0] = string(updateMessage)
	}

	msg, err := json.Marshal(updateArr)
	if err != nil {
		return err
	}

	return channel.Publish(
		"updateInstances", // exchange name
		routingKey,        // routing key
		false,             // mandatory
		false,             // immediate
		amqp.Publishing{Body: msg}, // message
	)
}

func (f *RealtimeWorkerController) sendChannelEvent(cml *models.ChannelMessageList, eventName string) error {
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

	byteMessage, err := json.Marshal(cm)
	if err != nil {
		return err
	}

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
	c, err := fetchChannel(channelId)
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

func fetchChannel(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	if err := c.ById(channelId); err != nil {
		return nil, err
	}
	return c, nil
}

func (f *RealtimeWorkerController) sendNotification(accountId int64, eventName string, data interface{}) error {
	channel, err := f.rmqConn.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	oldAccount, err := modelhelper.GetAccountBySocialApiId(accountId)
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
