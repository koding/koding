package realtimehelper

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"socialapi/config"
	"socialapi/models"
)

// send message to the channel
func MessageSaved(channelId, messageId int64) error {
	if !config.MustGet().GateKeeper.Pubnub.Enabled {
		return nil
	}

	c, err := models.ChannelById(channelId)
	if err != nil {
		return err
	}

	// populate cache
	cm, err := models.ChannelMessageById(messageId)
	if err != nil {
		return err
	}

	cm, err = cm.PopulateAddedBy()
	if err != nil {
		return err
	}

	cmc, err := cm.BuildEmptyMessageContainer()
	if err != nil {
		return err
	}

	if err := pushMessage(c, cmc, "MessageAdded"); err != nil {
		fmt.Println("error oldu", err)
		return err
	}

	return nil
}

func pushMessage(c *models.Channel, cmc *models.ChannelMessageContainer, eventName string) error {
	request := map[string]interface{}{
		"eventName":    eventName,
		"body":         cmc,
		"typeConstant": c.TypeConstant,
		"group":        c.GroupName,
	}

	payload, err := json.Marshal(request)
	if err != nil {
		return err
	}

	buf := bytes.NewBuffer(payload)
	client := &http.Client{}

	endpoint := fmt.Sprintf("%s/api/gatekeeper/channel/%s/push", config.MustGet().CustomDomain.Public, c.Name)
	res, err := client.Post(endpoint, "application/json", buf)
	if err != nil {
		return err
	}

	if res.StatusCode != 200 {
		return fmt.Errorf(res.Status)
	}

	return nil
}
