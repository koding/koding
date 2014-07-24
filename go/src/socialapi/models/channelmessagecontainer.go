package models

import (
	"socialapi/request"

	"github.com/koding/bongo"
)

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

	if cmc.Message == nil {
		cmc.Err = ErrMessageIsNotSet
		return cmc
	}

	// do not process from now on, if the container has Err
	if cmc.Err != nil {
		return cmc
	}

	cmc.Err = f(cmc)

	return cmc
}

func (c *ChannelMessageContainer) Fetch(id int64, q *request.Query) error {
	if q.ShowExempt {
		cmc, err := BuildChannelMessageContainer(id, q)
		if err != nil {
			return err
		}
		*c = *cmc

	} else {
		if err := bongo.B.Fetch(c, id); err != nil {
			return err
		}

		return c.UpdateReplies(q).Err
	}

	return nil
}

func (c *ChannelMessageContainer) TableName() string {
	return "api.channel_message"
}

func (c *ChannelMessageContainer) GetId() int64 {
	if c.Message != nil {
		return c.Message.Id
	}

	return 0
}

func (c *ChannelMessageContainer) PopulateWith(m *ChannelMessage) *ChannelMessageContainer {
	c.Message = m
	c.AddAccountOldId()
	return c
}

func (cc *ChannelMessageContainer) AddAccountOldId() *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		if c.AccountOldId != "" {
			return nil
		}

		oldId, err := FetchAccountOldIdByIdFromCache(c.Message.AccountId)
		if err != nil {
			return err
		}

		c.AccountOldId = oldId

		return nil
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

		if c.Message.TypeConstant == ChannelMessage_TYPE_REPLY {
			// if message itself already a reply, no need to add replies to it
			return nil
		}

		// fetch the replies
		mr := NewMessageReply()
		mr.MessageId = c.Message.Id

		q := query.Clone()
		q.Limit = query.ReplyLimit
		q.Skip = query.ReplySkip

		replies, err := mr.List(q)
		if err != nil {
			return err
		}

		// populate the replies as containers
		rs := NewChannelMessageContainers()
		rs.PopulateWith(replies, query)

		// set channel message containers
		c.Replies = *rs
		return nil
	})

}

func (c *ChannelMessageContainer) UpdateReplies(q *request.Query) *ChannelMessageContainer {
	if len(c.Replies) > 0 {
		for i, _ := range c.Replies {
			if err := c.Replies[i].Fetch(c.Replies[i].GetId(), q); err != nil {
				c.Replies[i].Err = err
			}
		}
	}

	return c
}

func (cc *ChannelMessageContainer) AddRepliesCount(query *request.Query) *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		// fetch the replies
		mr := NewMessageReply()
		mr.MessageId = c.Message.Id

		repliesCount, err := mr.Count(query)
		if err != nil {
			return err
		}

		c.RepliesCount = repliesCount

		return nil
	})
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
			return err
		}

		c.Interactions[q.Type] = interactionContainer

		return nil
	})
}

func (cc *ChannelMessageContainer) AddIsInteracted(query *request.Query) *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		i := NewInteraction()
		i.MessageId = c.Message.Id
		isInteracted, err := i.IsInteracted(query.AccountId)
		if err != nil {
			return err
		}

		c.Interactions["like"].IsInteracted = isInteracted
		return nil
	})
}

func (cc *ChannelMessageContainer) AddIsFollowed(query *request.Query) *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		isFollowed, err := c.Message.CheckIsMessageFollowed(query)
		c.IsFollowed = isFollowed
		return err
	})
}

func (cc *ChannelMessageContainer) AddUnreadRepliesCount() *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		panic("method not implemented")
		return nil
	})
}

type ChannelMessageContainers []ChannelMessageContainer

func NewChannelMessageContainers() *ChannelMessageContainers {
	return &ChannelMessageContainers{}
}

func (ccs *ChannelMessageContainers) PopulateWith(cms []ChannelMessage, query *request.Query) *ChannelMessageContainers {
	for i, _ := range cms {
		cmc := NewChannelMessageContainer()
		cmc.PopulateWith(&cms[i])
		cmc.SetGenerics(query)
		ccs.Add(cmc)
	}

	return ccs
}

func (ccs *ChannelMessageContainers) Add(containers ...*ChannelMessageContainer) *ChannelMessageContainers {
	for _, cc := range containers {
		*ccs = append(*ccs, *cc)
	}

	return ccs
}
