package models

import "socialapi/request"

type ChannelMessageContainer struct {
	Message      *ChannelMessage `json:"message"`
	RepliesCount int             `json:"repliesCount"`
	// Replies should stay as   ChannelMessageContainers
	// not as a pointer
	Replies            ChannelMessageContainers `json:"replies"`
	AccountOldId       string                   `json:"accountOldId"`
	IsFollowed         bool                     `json:"isFollowed"`
	UnreadRepliesCount int                      `json:"unreadRepliesCount,omitempty"`
	ParentID           int64                    `json:"parentId,omitempty,string"`
	Err                error                    `json:"-"`
}

// Tests are done.
func NewChannelMessageContainer() *ChannelMessageContainer {
	container := &ChannelMessageContainer{}

	return container
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
	cmc, err := BuildChannelMessageContainer(id, q)
	if err != nil {
		return err
	}
	*c = *cmc

	return nil
}

// Tests are done.
func (c *ChannelMessageContainer) BongoName() string {
	return "api.channel_message"
}

// Tests are done.
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

// Tests are done
func (cc *ChannelMessageContainer) AddAccountOldId() *ChannelMessageContainer {
	return withChannelMessageContainerChecks(cc, func(c *ChannelMessageContainer) error {
		if c.AccountOldId != "" {
			return nil
		}

		acc, err := Cache.Account.ById(c.Message.AccountId)
		if err != nil {
			return err
		}

		c.AccountOldId = acc.OldId

		return nil
	})
}

func (c *ChannelMessageContainer) SetGenerics(query *request.Query) *ChannelMessageContainer {
	c.AddReplies(query)
	c.AddRepliesCount(query)

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
		for i := range c.Replies {
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
	})
}

type ChannelMessageContainers []ChannelMessageContainer

func NewChannelMessageContainers() *ChannelMessageContainers {
	return &ChannelMessageContainers{}
}

func (ccs *ChannelMessageContainers) PopulateWith(cms []ChannelMessage, query *request.Query) *ChannelMessageContainers {
	for i := range cms {
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

func (ccs *ChannelMessageContainers) Err() error {
	for _, cc := range *ccs {
		if cc.Err != nil {
			return cc.Err
		}
	}

	return nil
}
