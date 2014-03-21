package followingfeed

import (
	"errors"
	"fmt"
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
		"channel_message_created": (*FollowingFeedController).MessageSaved,
		"channel_message_update":  (*FollowingFeedController).MessageUpdated,
		"channel_message_deleted": (*FollowingFeedController).MessageDeleted,
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
	fmt.Println("saved")
	return nil
}

func (f *FollowingFeedController) MessageUpdated(data []byte) error {
	fmt.Println("update")

	return nil

}

func (f *FollowingFeedController) MessageDeleted(data []byte) error {
	fmt.Println("delete")

	return nil
}

func mapMessage(data []byte) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func isChannelEligible(cm *models.ChannelMessage) (bool, error) {
	c, err := fetchChannel(cm.InitialChannelId)
	if err != nil {
		return false, err
	}

	if c.Name != models.Channel_KODING_NAME {
		return false, nil
	}

	return true, nil
}
// todo add caching here
func fetchChannel(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	c.Id = channelId
	// todo - fetch only name here
	if err := c.Fetch(); err != nil {
		return nil, err
	}

	return c, nil
}
