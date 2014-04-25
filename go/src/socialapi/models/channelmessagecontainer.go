package models

type ChannelMessageContainer struct {
	Message      *ChannelMessage                  `json:"message"`
	Interactions map[string]*InteractionContainer `json:"interactions"`
	Replies      []*ChannelMessageContainer       `json:"replies"`
	AccountOldId string                           `json:"accountOldId"`
}

func NewChannelMessageContainer() *ChannelMessageContainer {
	return &ChannelMessageContainer{}
}

type InteractionContainer struct {
	IsInteracted  bool     `json:"isInteracted"`
	ActorsPreview []string `json:"actorsPreview"`
	ActorsCount   int      `json:"actorsCount"`
}

func NewInteractionContainer() *InteractionContainer {
	return &InteractionContainer{}
}
