package models

type ChannelMessageContainer struct {
	Message      *ChannelMessage
	Interactions map[string]*InteractionContainer
	Replies      []*ChannelMessageContainer
}

func NewChannelMessageContainer() *ChannelMessageContainer {
	return &ChannelMessageContainer{}
}

type InteractionContainer struct {
	Actors       []int64
	IsInteracted bool
}

func NewInteractionContainer() *InteractionContainer {
	return &InteractionContainer{}
}
