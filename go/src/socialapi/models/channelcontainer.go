package models

type ChannelContainer struct {
	Channel             Channel                  `json:"channel"`
	IsParticipant       bool                     `json:"isParticipant"`
	ParticipantCount    int                      `json:"participantCount"`
	ParticipantsPreview []string                 `json:"participantsPreview,omitempty"`
	LastMessage         *ChannelMessageContainer `json:"lastMessage,omitempty"`
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
	participantOldIds, err := AccountOldsIdByIds(cpList)
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
