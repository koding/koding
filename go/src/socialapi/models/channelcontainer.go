package models

import "fmt"

type ChannelContainer struct {
	Channel             Channel         `json:"channel"`
	IsParticipant       bool            `json:"isParticipant"`
	ParticipantCount    int             `json:"participantCount"`
	ParticipantsPreview []int64         `json:"participantsPreview,omitempty"`
	LastMessage         *ChannelMessage `json:"lastMessage,omitempty"`
}

func NewChannelContainer() *ChannelContainer {
	return &ChannelContainer{}
}

func PopulateChannelContainers(channelList []Channel, accountId int64) []*ChannelContainer {
	channelContainers := make([]*ChannelContainer, len(channelList))

	for i, channel := range channelList {
		channelContainers[i] = PopulateChannelContainer(channel, accountId)
	}

	return channelContainers
}

func PopulateChannelContainer(channel Channel, accountId int64) *ChannelContainer {

	cp := NewChannelParticipant()
	cp.ChannelId = channel.Id

	// add participantCount
	participantCount, err := cp.FetchParticipantCount()
	if err != nil {
		fmt.Println(err)
	}

	// add participation status
	isParticipant, err := cp.IsParticipant(accountId)
	if err != nil {
		fmt.Println(err)
	}

	cc := NewChannelContainer()
	cc.Channel = channel
	cc.IsParticipant = isParticipant
	cc.ParticipantCount = participantCount

	return cc
}
