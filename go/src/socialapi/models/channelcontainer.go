package models

import "fmt"

type ChannelContainer struct {
	Channel          Channel `json:"channel"`
	IsParticipated   bool    `json:"isParticipated"`
	ParticipantCount int     `json:"participantCount"`
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
	isParticipated, err := cp.IsParticipated(accountId)
	if err != nil {
		fmt.Println(err)
	}

	cc := NewChannelContainer()
	cc.Channel = channel
	cc.IsParticipated = isParticipated
	cc.ParticipantCount = participantCount

	return cc
}
