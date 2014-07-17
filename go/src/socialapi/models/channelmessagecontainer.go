package models

type ChannelMessageContainer struct {
	Message      *ChannelMessage                  `json:"message"`
	Interactions map[string]*InteractionContainer `json:"interactions"`
	RepliesCount int                              `json:"repliesCount"`
	// Replies should stay as   ChannelMessageContainers
	// not as a pointer
	Replies            ChannelMessageContainers `json:"replies"`
	AccountOldId       string                   `json:"accountOldId"`
	IsFollowed         bool                     `json:"isFollowed"`
	UnreadRepliesCount int                      `json:"unreadRepliesCount,omitempty"`
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
