package models

type ChannelContainer struct {
	Channel             Channel                  `json:"channel"`
	IsParticipant       bool                     `json:"isParticipant"`
	ParticipantCount    int                      `json:"participantCount"`
	ParticipantsPreview []string                 `json:"participantsPreview"`
	LastMessage         *ChannelMessageContainer `json:"lastMessage"`
	UnreadCount         int                      `json:"unreadCount"`
}

func NewChannelContainer() *ChannelContainer {
	return &ChannelContainer{}
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

func PopulateChannelContainersWithUnreadCount(channelList []Channel, accountId int64) ([]*ChannelContainer, error) {
	channelContainers, err := PopulateChannelContainers(channelList, accountId)
	if err != nil {
		return nil, err
	}

	cml := NewChannelMessageList()
	for i, container := range channelContainers {
		if !container.IsParticipant {
			continue
		}

		cp := NewChannelParticipant()
		cp.ChannelId = container.Channel.Id
		cp.AccountId = accountId
		if err := cp.FetchParticipant(); err != nil {
			// helper.MustGetLogger().Error(err.Error())
			continue
		}

		// for private messages calculate the unread reply count
		if container.Channel.TypeConstant == Channel_TYPE_PRIVATE_MESSAGE {
			if container.LastMessage == nil || container.LastMessage.Message == nil || container.LastMessage.Message.Id == 0 {
				continue
			}

			count, err := NewMessageReply().UnreadCount(container.LastMessage.Message.Id, cp.LastSeenAt, false)
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
