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

func (f *RealtimeWorkerController) MessageSaved(data []byte) error {
	fmt.Println("MessageSaved")
	return nil
}

func (f *RealtimeWorkerController) MessageUpdated(data []byte) error {
	fmt.Println("MessageUpdate")
	return nil
}

func (f *RealtimeWorkerController) MessageDeleted(data []byte) error {

	fmt.Println("MessageSaved")

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
