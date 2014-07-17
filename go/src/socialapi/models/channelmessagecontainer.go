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
	interactionContainer := &InteractionContainer{}
	interactionContainer.ActorsPreview = make([]string, 0)
	interactionContainer.IsInteracted = false
	interactionContainer.ActorsCount = 0

	return interactionContainer
}

func withChannelMessageContainerChecks(cmc *ChannelMessageContainer, f func(c *ChannelMessageContainer) error) *ChannelMessageContainer {
	if cmc == nil {
		cmc = NewChannelMessageContainer()
		cmc.Err = ErrMessageIsNotSet
		return cmc
	}

	if cmc.Err != nil {
		return cmc
	}

	cmc.Err = f(cmc)

	return cmc
}

func (c *ChannelMessageContainer) PopulateWith(m *ChannelMessage) *ChannelMessageContainer {
	c.Message = m
	c.AddAccountOldId()
	return c
}

func (c *ChannelMessageContainer) AddAccountOldId() *ChannelMessageContainer {
	if c.AccountOldId != "" {
		return c
	}

	oldId, err := FetchAccountOldIdByIdFromCache(c.Message.AccountId)
	if err != nil {
		c.Err = err
		return c
	}

	c.AccountOldId = oldId
	return c
}
func (c *ChannelMessageContainer) AddReplies(query *request.Query) *ChannelMessageContainer {
	if c.Message != nil && c.Message.TypeConstant == ChannelMessage_TYPE_REPLY {
		// if message itself already a reply, no need to add replies to it
		return c
	}

	// fetch the replies
	mr := NewMessageReply()
	mr.MessageId = c.Message.Id

	q := query.Clone()
	q.Limit = query.ReplyLimit
	q.Skip = query.ReplySkip

	replies, err := mr.List(q)
	if err != nil {
		c.Err = err
		return c
	}

	// populate the replies as containers
	rs := NewChannelMessageContainers()
	rs.PopulateWith(replies, query)

	// set channel message containers
	c.Replies = *rs
	return c
}

func (c *ChannelMessageContainer) AddInteractions(query *request.Query) *ChannelMessageContainer {
	i := NewInteraction()
	i.MessageId = c.Message.Id

	// get preview
	q := query.Clone()
	q.Type = "like"
	q.Limit = 3

	interactionContainer, err := i.FetchInteractionContainer(q)
	if err != nil {
		c.Err = err
		return c
	}

	c.Interactions[q.Type] = interactionContainer

	return c

}

func (c *ChannelMessageContainer) AddIsFollowed(query *request.Query) *ChannelMessageContainer {
	isFollowed, err := c.Message.CheckIsMessageFollowed(query)
	c.IsFollowed = isFollowed
	c.Err = err
	return c
}

func (c *ChannelMessageContainer) AddUnreadRepliesCount() *ChannelMessageContainer {
	return c
}

type ChannelMessageContainers []ChannelMessageContainer

func NewChannelMessageContainers() *ChannelMessageContainers {
	return &ChannelMessageContainers{}
}

func (c *ChannelMessageContainers) PopulateWith(cms []ChannelMessage, query *request.Query) *ChannelMessageContainers {
	for i, _ := range cms {
		cmc := NewChannelMessageContainer()
		cmc.PopulateWith(&cms[i])
		cmc.SetGenerics(query)
		c.Add(cmc)
	}

	return c
}

func (c *ChannelMessageContainers) Add(containers ...*ChannelMessageContainer) *ChannelMessageContainers {
	for _, cc := range containers {
		*c = append(*c, *cc)
	}
	return c
}
