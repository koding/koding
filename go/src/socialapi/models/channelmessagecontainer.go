package models

import "socialapi/request"

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
	Err                error                    `json:"-"`
}

func NewChannelMessageContainer() *ChannelMessageContainer {
	container := &ChannelMessageContainer{}
	container.Interactions = make(map[string]*InteractionContainer)
	container.Interactions["like"] = NewInteractionContainer()

	return container
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

func (cc *ChannelMessageContainer) AddAccountOldId() *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {

		if c.AccountOldId != "" {
			return c
		}

		oldId, err := FetchAccountOldIdByIdFromCache(c.Message.AccountId)
		if err != nil {
			c.Err = err
			return c
		}

		c.AccountOldId = oldId
	})
}

func (c *ChannelMessageContainer) SetGenerics(query *request.Query) *ChannelMessageContainer {
	c.AddReplies(query)
	c.AddRepliesCount(query)
	c.AddInteractions(query)
	return c
}

func (cc *ChannelMessageContainer) AddReplies(query *request.Query) *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {

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
	})

}
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

func (c *ChannelMessageContainer) AddRepliesCount(query *request.Query) *ChannelMessageContainer {
	// fetch the replies
	mr := NewMessageReply()
	mr.MessageId = c.Message.Id

	repliesCount, err := mr.Count(query)
	c.Err = err
	c.RepliesCount = repliesCount

	return c
}

func (cc *ChannelMessageContainer) AddInteractions(query *request.Query) *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {

		// get preview
		q := query.Clone()
		q.Type = "like"
		q.Limit = 3

		// if the message is reply do not add  isInteracted data
		if c.Message.TypeConstant == ChannelMessage_TYPE_REPLY {
			q.AddIsInteracted = false
		}

		i := NewInteraction()
		i.MessageId = c.Message.Id
		interactionContainer, err := i.FetchInteractionContainer(q)
		if err != nil {
			c.Err = err
			return c
		}

		c.Interactions[q.Type] = interactionContainer

		return c
	})
}

func (c *ChannelMessageContainer) AddIsInteracted(query *request.Query) *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		i := NewInteraction()
		i.MessageId = c.Message.Id
		isInteracted, err := i.IsInteracted(query.AccountId)
		if err != nil {
			c.Err = err
			return c
		}

		c.Interactions["like"].IsInteracted = isInteracted

		return c
	})
}

func (cc *ChannelMessageContainer) AddIsFollowed(query *request.Query) *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		isFollowed, err := c.Message.CheckIsMessageFollowed(query)
		c.IsFollowed = isFollowed
		c.Err = err
		return c
	})
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
