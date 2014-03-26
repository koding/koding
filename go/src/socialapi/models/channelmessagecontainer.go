package models

type ChannelMessageContainer struct {
	Message      *ChannelMessage                  `json:"message"`
	Interactions map[string]*InteractionContainer `json:"interactions"`
	Replies      []*ChannelMessageContainer       `json:"replies"`
}

func NewChannelMessageContainer() *ChannelMessageContainer {
	return &ChannelMessageContainer{}
}

type InteractionContainer struct {
	Actors       []int64 `json:"actors"`
	IsInteracted bool    `json:"isInteracted"`
}

func NewInteractionContainer() *InteractionContainer {
	return &InteractionContainer{}
}
