package realtime

import (
	"errors"
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
	return nil
}

func (f *RealtimeWorkerController) MessageUpdated(data []byte) error {
	return nil
}

func (f *RealtimeWorkerController) MessageDeleted(data []byte) error {
	return nil
}
