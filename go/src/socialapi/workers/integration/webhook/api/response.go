package api

import "socialapi/models"

type BotChannelResponse struct {
	*models.ChannelContainer
}

func NewBotChannelResponse() *BotChannelResponse {
	return &BotChannelResponse{}
}
