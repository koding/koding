package models

import (
	"socialapi/request"

	"github.com/koding/bongo"
)

type ChannelContainer struct {
	Channel             *Channel                 `json:"channel"`
	IsParticipant       bool                     `json:"isParticipant"`
	ParticipantCount    int                      `json:"participantCount"`
	ParticipantsPreview []string                 `json:"participantsPreview"`
	LastMessage         *ChannelMessageContainer `json:"lastMessage"`
	UnreadCount         int                      `json:"unreadCount"`
	Err                 error                    `json:"-"`
}

func NewChannelContainer() *ChannelContainer {
	return &ChannelContainer{}
}

func (c *ChannelContainer) TableName() string {
	return "api.channel"
}

func (c *ChannelContainer) Fetch(id int64, q *request.Query) error {
	if q.ShowExempt {
		cc, err := BuildChannelContainer(id, q)
		if err != nil {
			return err
		}
		*c = *cc
	} else {
		return bongo.B.Fetch(c, id)
	}

	return nil
}

func (c *ChannelContainer) GetId() int64 {
	if c.Channel != nil {
		return c.Channel.Id
	}

	return 0
}

func (cr *ChannelContainer) PopulateWith(c Channel, accountId int64) error {
	cr.Channel = &c
	cr.AddParticipantCount().
		AddParticipantsPreview().
		AddIsParticipant(accountId).
		AddLastMessage()

	return cr.Err
}

func withChecks(cc *ChannelContainer, f func(c *ChannelContainer) error) *ChannelContainer {
	if cc == nil {
		cc = &ChannelContainer{}
		cc.Err = ErrChannelContainerIsNotSet
		return cc
	}

	if cc.Err != nil {
		return cc
	}

	if cc.Channel == nil {
		cc.Err = ErrChannelIsNotSet
		return cc
	}

	cc.Err = f(cc)

	return cc
}

func (cr *ChannelContainer) AddParticipantCount() *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {
		cp := NewChannelParticipant()
		cp.ChannelId = cc.Channel.Id
		// fetch participant count from db
		participantCount, err := cp.FetchParticipantCount()
		if err != nil {
			return err
		}

		cc.ParticipantCount = participantCount
		return nil
	})
}

func (cr *ChannelContainer) AddParticipantsPreview() *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {
		maxParticipantCount := 5
		// try to use the data
		if cc.ParticipantCount > maxParticipantCount {
			if len(cc.ParticipantsPreview) == maxParticipantCount {
				return nil
			}
		}

		cp := NewChannelParticipant()
		cp.ChannelId = cc.Channel.Id

		// get participant preview
		cpList, err := cp.ListAccountIds(maxParticipantCount)
		if err != nil {
			return err
		}

		// get their old mongo ids from system
		participantOldIds, err := FetchAccountOldsIdByIdsFromCache(cpList)
		if err != nil {
			return err
		}

		cc.ParticipantsPreview = participantOldIds

		return nil
	})
}

func (cr *ChannelContainer) AddIsParticipant(accountId int64) *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {
		if accountId == 0 {
			return nil
		}

		// if data is already set, use it
		if cc.IsParticipant {
			return nil
		}

		cp := NewChannelParticipant()
		cp.ChannelId = cc.Channel.Id

		// add participation status
		isParticipant, err := cp.IsParticipant(accountId)
		if err != nil {
			return err
		}

		cc.IsParticipant = isParticipant

		return nil
	})
}

func (cr *ChannelContainer) AddLastMessage() *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {
		// add last message of the channel
		cm, err := cc.Channel.FetchLastMessage()
		if err != nil {
			return err
		}

		if cm != nil {
			cmc, err := cm.BuildEmptyMessageContainer()
			if err != nil {
				return err
			}
			cc.LastMessage = cmc
		}

		return nil
	})
}

func getChannelParticipant(channelId, accountId int64) (*ChannelParticipant, error) {
	// fetch participant data from db
	cp := NewChannelParticipant()
	cp.ChannelId = channelId
	cp.AccountId = accountId
	if err := cp.FetchParticipant(); err != nil {
		return nil, err
	}

	return cp, nil
}

func (cr *ChannelContainer) AddUnreadCount(accountId int64) *ChannelContainer {
	return withChecks(cr, func(cc *ChannelContainer) error {

		cml := NewChannelMessageList()

		// if the user is not a participant of the channel, do not add unread
		// count
		if !cc.IsParticipant {
			return nil
		}

		// for private messages calculate the unread reply count
		if cc.Channel.TypeConstant == Channel_TYPE_PRIVATE_MESSAGE {
			// validate that last message is set
			if cc.LastMessage == nil || cc.LastMessage.Message == nil || cc.LastMessage.Message.Id == 0 {
				return nil
			}

			cp, err := getChannelParticipant(cc.Channel.Id, accountId)
			if err != nil {
				return err
			}

			isExempt := cp.MetaBits.Is(Troll)

			count, err := NewMessageReply().UnreadCount(
				cc.LastMessage.Message.Id,
				cp.LastSeenAt,
				isExempt,
			)

			if err != nil {
				return err
			}

			cc.UnreadCount = count
			return nil
		}

		cp, err := getChannelParticipant(cc.Channel.Id, accountId)
		if err != nil {
			return err
		}

		count, err := cml.UnreadCount(cp)
		if err != nil {
			return err
		}

		cc.UnreadCount = count

		return nil

	})
}

type ChannelContainers []ChannelContainer

func NewChannelContainers() *ChannelContainers {
	return &ChannelContainers{}
}

func (c *ChannelContainers) PopulateWith(channelList []Channel, accountId int64) *ChannelContainers {
	for i, _ := range channelList {
		cc := NewChannelContainer()
		cc.PopulateWith(channelList[i], accountId)
		c.Add(cc)
	}

	return c
}

func (c *ChannelContainers) Fetch(channelList []Channel, query *request.Query) error {
	for i, _ := range channelList {
		cc := NewChannelContainer()
		if err := cc.Fetch(channelList[i].GetId(), query); err != nil {
			cc.Err = err
		}
		c.Add(cc)
	}

	return nil
}

func (c *ChannelContainers) AddIsParticipant(accountId int64) *ChannelContainers {
	for i, container := range *c {
		(*c)[i] = *container.AddIsParticipant(accountId)
	}

	return c
}

func (c *ChannelContainers) AddUnreadCount(accountId int64) *ChannelContainers {
	for i, container := range *c {
		(*c)[i] = *container.AddUnreadCount(accountId)
	}

	return c
}

func (c *ChannelContainers) AddLastMessage() *ChannelContainers {
	for i, container := range *c {
		(*c)[i] = *container.AddLastMessage()
	}

	return c
}

func (c *ChannelContainers) Add(containers ...*ChannelContainer) {
	for _, cc := range containers {
		*c = append(*c, *cc)
	}
}

func (c ChannelContainers) Err() error {
	for _, container := range c {
		if container.Err != nil {
			return container.Err
		}
	}

	// // TODO filter or re-populate err-ed content

	return nil
}
