package realtimehelper

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"strconv"

	"github.com/koding/bongo"
)

const NotificationTypeMessage = "message"

func PushMessage(c *models.Channel, eventName string, body interface{}) error {

	request := map[string]interface{}{
		"eventName": eventName,
		"body":      body,
		"channel": map[string]interface{}{
			"id":           strconv.FormatInt(c.Id, 10),
			"name":         c.Name,
			"typeConstant": c.TypeConstant,
			"groupName":    c.GroupName,
			"token":        c.Token,
		},
	}

	return bongo.B.Emit("dispatcher_channel_updated", request)
}

func UpdateInstance(m *models.ChannelMessage, eventName string, body interface{}) error {
	// While sending message instance updates, instead of creating new PubNub channel for each message
	// we are sending the events to parent channels. For this reason, we need channel tokens.
	// For public messages we are sending instance events to each message's group channel
	c, err := m.FetchParentChannel()
	if err != nil {
		return err
	}

	request := map[string]interface{}{
		"token":        m.Token,
		"eventName":    eventName,
		"body":         body,
		"messageId":    m.Id,
		"channelToken": c.Token,
	}

	return bongo.B.Emit("dispatcher_message_updated", request)
}

func NotifyUser(a *models.Account, eventName string, body interface{}, groupName string) error {
	request := map[string]interface{}{
		"account":   a,
		"eventName": NotificationTypeMessage,
		"body": map[string]interface{}{
			"event":    eventName,
			"contents": body,
			"context":  groupName,
		},
	}

	return bongo.B.Emit("dispatcher_notify_user", request)
}

func SubscribeMessage(cm *models.ChannelMessage) error {
	newCm := models.NewChannelMessage()
	newCm.Token = cm.Token
	request := &handler.Request{
		Type:     "POST",
		Endpoint: "/api/gatekeeper/subscribe/message",
		Body:     newCm,
		Headers: map[string]string{
			"Accept":       "application/json",
			"Content-Type": "application/json",
		},
	}

	resp, err := handler.DoRequest(request)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Need a better response
	if resp.StatusCode != 200 {
		return fmt.Errorf(resp.Status)
	}

	return nil
}
