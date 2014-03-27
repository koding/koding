package realtime

import (
	"errors"
	"fmt"
	"koding/tools/logger"
)

type Action func(*RealtimeWorkerController, []byte) error

type RealtimeWorkerController struct {
	routes map[string]Action
	log    logger.Log
}

var HandlerNotFoundErr = errors.New("Handler Not Found")

func NewRealtimeWorkerController(log logger.Log) *RealtimeWorkerController {
	ffc := &RealtimeWorkerController{
		log: log,
	}

	routes := map[string]Action{
		"channel_message_created": (*RealtimeWorkerController).MessageSaved,
		"channel_message_update":  (*RealtimeWorkerController).MessageUpdated,
		"channel_message_deleted": (*RealtimeWorkerController).MessageDeleted,

		"interaction_created": (*RealtimeWorkerController).InteractionSaved,
		"interaction_deleted": (*RealtimeWorkerController).InteractionDeleted,
		"channel_message_list_created": (*RealtimeWorkerController).MessageListSaved,
		"channel_message_list_update":  (*RealtimeWorkerController).MessageListUpdated,
		"channel_message_list_deleted": (*RealtimeWorkerController).MessageListDeleted,
	}

	ffc.routes = routes

	return ffc
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


func mapMessageToInteraction(data []byte) (*models.Interaction, error) {
	i := models.NewInteraction()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}
func (f *RealtimeWorkerController) MessageSaved(data []byte) error {
	fmt.Println("MessageSaved")
	return nil
}

func (f *RealtimeWorkerController) MessageUpdated(data []byte) error {
	cm, err := mapMessageToChannelMessage(data)
	if err != nil {
		return err
	}

	err = sendInstanceEvent(cm, "updateInstance")
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

	err = sendInstanceEvent(i, "InteractionSaved")
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

	err = sendInstanceEvent(i, "InteractionDeleted")
	if err != nil {
		fmt.Println(err)
		return err
	}

	return nil
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

func sendInstanceEvent(message bongo.Modellable, eventName string) error {
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

	for _, secretName := range secretNames {
		routingKey := secretName + "." + eventName

		byteMessage, err := json.Marshal(cml)
		if err != nil {
			return err
		}

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
	_, err := fetchChannel(channelId)
	if err != nil {
		return names, err
	}

	// todo - implement fetching from mongo database
	names = append(names, "foo")
	names = append(names, "bar")
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
