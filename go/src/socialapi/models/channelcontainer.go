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

func PopulateChannelContainers(channelList []Channel, accountId int64) ([]*ChannelContainer, error) {
	channelContainers := make([]*ChannelContainer, len(channelList))

	var err error
	for i, channel := range channelList {
		channelContainers[i], err = PopulateChannelContainer(channel, accountId)
		if err != nil {
			return nil, err
		}
	}

	return channelContainers, nil
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
			if err != nil {
				continue
			}

			channelContainers[i].UnreadCount = count
			continue
		}

		count, _ := cml.UnreadCount(cp)
		if err != nil {
			// helper.MustGetLogger().Error(err.Error())
			continue
		}
		channelContainers[i].UnreadCount = count
	}

	return channelContainers, nil
}

func PopulateChannelContainer(channel Channel, accountId int64) (*ChannelContainer, error) {
	cp := NewChannelParticipant()
	cp.ChannelId = channel.Id

	// add participantCount
	participantCount, err := cp.FetchParticipantCount()
	if err != nil {
		return nil, err
	}

	// add participant preview
	cpList, err := cp.ListAccountIds(5)
	if err != nil {
		return nil, err
	}

	// add participation status
	isParticipant, err := cp.IsParticipant(accountId)
	if err != nil {
		return nil, err
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
	}

	cc := NewChannelContainer()
	cc.Channel = channel
	cc.IsParticipant = isParticipant
	cc.ParticipantCount = participantCount
	participantOldIds, err := FetchAccountOldsIdByIdsFromCache(cpList)
	if err != nil {
		return nil, err
	}

	cc.ParticipantsPreview = participantOldIds

	// add last message of the channel
	cm, err := channel.FetchLastMessage()
	if err != nil {
		return nil, err
	}

	if cm != nil {
		cmc, err := cm.BuildEmptyMessageContainer()
		if err != nil {
			return nil, err
		}
		cc.LastMessage = cmc
	}

	return cc, nil
}
