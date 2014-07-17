package models

type ChannelContainer struct {
	Channel             Channel                  `json:"channel"`
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

func (c *ChannelContainer) ById(id int64) (*ChannelContainer, error) {
	return c, nil
}

func withChecks(cc *ChannelContainer, f func(c *ChannelContainer) error) *ChannelContainer {
	if cc == nil {
		cc = &ChannelContainer{}
		cc.Err = ErrChannelContainerIsNotSet
		return cc
	}

	// if cc.Channel == (*Channel{}) {
	// 	cc.Err = ErrChannelIsNotSet
	// 	return cc
	// }

	if cc.Err != nil {
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
		// try to use the data
		if cc.ParticipantCount > 5 {
			if len(cc.ParticipantsPreview) == 5 {
				return nil
			}
		}

		cp := NewChannelParticipant()
		cp.ChannelId = cc.Channel.Id

		// get participant preview
		cpList, err := cp.ListAccountIds(5)
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

			count, err := NewMessageReply().UnreadCount(cc.LastMessage.Message.Id, cp.LastSeenAt)
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

func (cr *ChannelContainer) PopulateWith(c Channel, accountId int64) error {
	cr.Channel = c
	cr.AddParticipantCount().
		AddParticipantsPreview().
		AddIsParticipant(accountId).
		AddLastMessage()

	return cr.Err
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

func (c *ChannelContainers) AddUnreadCount(accountId int64) *ChannelContainers {
	for i, container := range *c {
		(*c)[i] = *container.AddUnreadCount(accountId)
	}

	return c
}

func (c *ChannelContainers) Add(containers ...*ChannelContainer) {
	for _, cc := range containers {
		*c = append(*c, *cc)
	}
}

func (c ChannelContainers) Validate() ChannelContainers {
	hasErr := false
	for _, container := range c {
		if container.Err != nil {
			hasErr = true
			break
		}
	}

	if !hasErr {
		return c
	}

	// TODO filter or re-populate err-ed content

	return c
}
