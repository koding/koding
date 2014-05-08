package helper

import (
	"encoding/json"
	"socialapi/models"
)

func MapToChannelMessage(data []byte) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func MapToChannelMessageList(data []byte) (*models.ChannelMessageList, error) {
	cm := models.NewChannelMessageList()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func MapToInteraction(data []byte) (*models.Interaction, error) {
	i := models.NewInteraction()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}

func MapToMessageReply(data []byte) (*models.MessageReply, error) {
	i := models.NewMessageReply()
	if err := json.Unmarshal(data, i); err != nil {
		return nil, err
	}

	return i, nil
}
