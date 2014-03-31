package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"socialapi/models"
)

var (
	PARTICIPANT_COUNT = 4
)

func testFrontpageOperations() {

	var accounts []int64
	for i := 0; i < 2; i++ {
		accounts = append(accounts, rand.Int63())
	}

	for i := 0; i < len(accounts); i++ {
		_, err := populateChannelwithAccount(accounts[i])
		if err != nil {
			fmt.Println(err)
			return
		}
	}

	for i := 0; i < len(accounts); i++ {
		channels, err := fetchChannels(accounts[i])
		if err != nil {
			fmt.Println(err)
			return
		}
		for j := 0; j < len(channels); j++ {
			fetchHistoryAndCheckMessages(channels[j].Id, accounts[i])
		}
	}
}
func fetchHistoryAndCheckMessages(channelId, accountId int64) {
	history, err := getHistory(channelId, accountId)
	if err != nil {
		fmt.Println(err)
		return
	}

	if len(history.MessageList) != PARTICIPANT_COUNT {
		fmt.Println("history should have 4 messages", len(history.MessageList))
		return
	}

	for i := 0; i < len(history.MessageList); i++ {
		if len(history.MessageList[i].Replies) != PARTICIPANT_COUNT {
			fmt.Println("replies count should be PARTICIPANT_COUNT", len(history.MessageList[i].Replies))
		}
		if len(history.MessageList[i].Interactions) != 1 {
			fmt.Println("interaction count should be PARTICIPANT_COUNT", len(history.MessageList[i].Interactions))
		}
	}

	// fmt.Println(history.UnreadCount)
}

func populateChannelwithAccount(accountId int64) (*models.Channel, error) {
	channel, err := createChannel()
	if err != nil {
		return nil, err
	}

	_, err = addChannelParticipant(channel.Id, accountId)
	if err != nil {
		return nil, err
	}

	participants, err := createChannelParticipants(channel.Id, PARTICIPANT_COUNT)
	if err != nil {
		return nil, err
	}

	//everyone will post status update
	for i := 0; i < len(participants); i++ {
		_, err := populatePost(channel.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}
	}

	return channel, nil

}

func fetchChannels(accountId int64) ([]*models.Channel, error) {
	url := fmt.Sprintf("/account/%d/channels", accountId)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var channels []*models.Channel
	err = json.Unmarshal(res, &channels)
	if err != nil {
		return nil, err
	}

	return channels, nil
}

func populatePost(channelId, accountId int64) (*models.ChannelMessage, error) {
	post, err := createPost(channelId, accountId)
	if err != nil {
		return nil, err
	}

	participants, err := createChannelParticipants(channelId, PARTICIPANT_COUNT)
	if err != nil {
		return nil, err
	}

	for i := 0; i < len(participants); i++ {
		reply, err := addReply(post.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}

		// add likes to replies
		err = addInteraction("like", reply.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}

		// like every comment
		err = addInteraction("like", reply.Id, accountId)
		if err != nil {
			return nil, err
		}

		// add likes to post
		err = addInteraction("like", post.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}

	}

	// like your post
	err = addInteraction("like", post.Id, accountId)
	if err != nil {
		return nil, err
	}

	return post, nil
}

func createChannelParticipants(channelId int64, c int) ([]*models.ChannelParticipant, error) {
	var participants []*models.ChannelParticipant
	for i := 0; i < c; i++ {
		participant, err := createChannelParticipant(channelId)
		if err != nil {
			return nil, err
		}

		participants = append(participants, participant)
	}

	return participants, nil
}
