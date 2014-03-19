package followingfeed

import (
	"errors"
	"koding/tools/logger"
)

type Action func(*FollowingFeedController, []byte) error

type FollowingFeedController struct {
	routes map[string]Action
	log    logger.Log
}

var HandlerNotFoundErr = errors.New("Handler Not Found")

func NewFollowingFeedController(log logger.Log) *FollowingFeedController {
	ffc := &FollowingFeedController{
		log: log,
	}

	routes := map[string]Action{
		"MessageSaved": (*FollowingFeedController).MessageSaved,
	}

	ffc.routes = routes

	return ffc
}

func (f *FollowingFeedController) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Recieved %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return HandlerNotFoundErr
	}

	return handler(f, data)
}

func (f *FollowingFeedController) MessageSaved(data []byte) error {
	return nil
}
