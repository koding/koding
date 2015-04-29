package api

type BotChannelResponse struct {
	ChannelId int64 `json:"channelId,string"`
}

func NewBotChannelResponse() *BotChannelResponse {
	return &BotChannelResponse{}
}
