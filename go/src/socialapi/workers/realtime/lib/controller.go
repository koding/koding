package realtime

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"strconv"
	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"

	"github.com/streadway/amqp"
)

type Action func(*RealtimeWorkerController, []byte) error

type RealtimeWorkerController struct {
	routes  map[string]Action
	log     logging.Logger
	rmqConn *amqp.Connection
	mongo   *mongodb.MongoDB
}

var HandlerNotFoundErr = errors.New("Handler Not Found")

func NewRealtimeWorkerController(rmq *rabbitmq.RabbitMQ, mongo *mongodb.MongoDB, log logging.Logger) (*RealtimeWorkerController, error) {
	rmqConn, err := rmq.Connect("NewRealtimeWorkerController")
	if err != nil {
		return nil, err
	}

	ffc := &RealtimeWorkerController{
		log:     log,
		mongo:   mongo,
		rmqConn: rmqConn.Conn(),
	}

	routes := map[string]Action{
		"channel_message_created": (*RealtimeWorkerController).MessageSaved,
		"channel_message_updated": (*RealtimeWorkerController).MessageUpdated,
		"channel_message_deleted": (*RealtimeWorkerController).MessageDeleted,

		"interaction_created": (*RealtimeWorkerController).InteractionSaved,
		"interaction_deleted": (*RealtimeWorkerController).InteractionDeleted,

		"message_reply_created": (*RealtimeWorkerController).MessageReplySaved,
		"message_reply_deleted": (*RealtimeWorkerController).MessageReplyDeleted,

		"channel_message_list_created": (*RealtimeWorkerController).MessageListSaved,
		"channel_message_list_updated": (*RealtimeWorkerController).MessageListUpdated,
		"channel_message_list_deleted": (*RealtimeWorkerController).MessageListDeleted,
	}

	ffc.routes = routes

	return ffc, nil
}

func (f *RealtimeWorkerController) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Recieved %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return HandlerNotFoundErr
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

func mapMessageToMessageReply(data []byte) (*models.Interaction, error) {
	i := models.NewInteraction()
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

	err = f.sendInstanceEvent(cm, "updateInstance")
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

func (f *RealtimeWorkerController) InteractionSaved(data []byte) error {
	i, err := mapMessageToInteraction(data)
	if err != nil {
		return err
	}

	err = f.sendInstanceEvent(i, "InteractionSaved")
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
}

func (f *RealtimeWorkerController) InteractionDeleted(data []byte) error {
	i, err := mapMessageToInteraction(data)
	if err != nil {
		return err
	}

	err = f.sendInstanceEvent(i, "InteractionDeleted")
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

	err = f.sendInstanceEvent(i, "MessageReplySaved")
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

	err = f.sendInstanceEvent(i, "MessageReplyDeleted")
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

	err = f.sendChannelEvent(cml, "MessageAddedToChannel")
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

	err = f.sendChannelEvent(cml, "MessageRemovedFromChannel")
	if err != nil {
		return err
	}
	return nil
}

func (f *RealtimeWorkerController) sendInstanceEvent(message bongo.Modellable, eventName string) error {
	channel, err := RMQConnection.Channel()
	if err != nil {
		return err
	}
	defer channel.Close()

	routingKey := "oid." + strconv.FormatInt(message.GetId(), 10) + ".event." + eventName

	updateMessage, err := json.Marshal(message)
	if err != nil {
		return err
	}

	updateArr := make([]string, 1)
	updateArr[0] = fmt.Sprintf("%s", string(updateMessage))

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
	channel, err := RMQConnection.Channel()
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

	byteMessage, err := json.Marshal(cml)
	if err != nil {
		return err
	}

	for _, secretName := range secretNames {
		routingKey := secretName + "." + eventName

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

	names, err = modelhelper.FetchFlattenedSecretName(c.Group)
	return names, nil
}

func fetchChannel(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	c.Id = channelId
	if err := c.Fetch(); err != nil {
		return nil, err
	}
	return c, nil
}
