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
	fmt.Println("MessageUpdate")
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

func (f *RealtimeWorkerController) MessageListSaved(data []byte) error {
	fmt.Println("MessageListSaved")
	return nil
}

func (f *RealtimeWorkerController) MessageListUpdated(data []byte) error {
	fmt.Println("MessageListUpdate")

	return nil
}

func (f *RealtimeWorkerController) MessageListDeleted(data []byte) error {
	fmt.Println("MessageListDelete")

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
