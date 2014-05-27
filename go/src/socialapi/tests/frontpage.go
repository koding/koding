package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/rest"

	"labix.org/v2/mgo/bson"
)

var (
	PARTICIPANT_COUNT = 4
)

func testFrontpageOperations() {

	var accounts []int64
	for i := 0; i < 2; i++ {
		account := models.NewAccount()
		account.OldId = bson.NewObjectId().Hex()
		account, _ = rest.CreateAccount(account)
		accounts = append(accounts, account.Id)
	}

	for i := 0; i < len(accounts); i++ {
		_, err := populateChannelwithAccount(accounts[i])
		if err != nil {
			fmt.Println(err)
			return
		}
	}

	for i := 0; i < len(accounts); i++ {
		channels, err := rest.FetchChannels(accounts[i])
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
	history, err := rest.GetHistory(channelId, accountId)
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
	channel, err := rest.CreateChannel(accountId)
	if err != nil {
		return nil, err
	}

	_, err = rest.AddChannelParticipant(channel.Id, accountId, accountId)
	if err != nil {
		return nil, err
	}

	participants, err := rest.CreateChannelParticipants(channel.Id, PARTICIPANT_COUNT)
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

func populatePost(channelId, accountId int64) (*models.ChannelMessage, error) {
	post, err := rest.CreatePost(channelId, accountId)
	if err != nil {
		return nil, err
	}

	participants, err := rest.CreateChannelParticipants(channelId, PARTICIPANT_COUNT)
	if err != nil {
		return nil, err
	}

	for i := 0; i < len(participants); i++ {
		reply, err := rest.AddReply(post.Id, participants[i].AccountId, post.InitialChannelId)
		if err != nil {
			return nil, err
		}

		// add likes to replies
		err = rest.AddInteraction("like", reply.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}

		// like every comment
		err = rest.AddInteraction("like", reply.Id, accountId)
		if err != nil {
			return nil, err
		}

		// add likes to post
		err = rest.AddInteraction("like", post.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}

	}

	// like your post
	err = rest.AddInteraction("like", post.Id, accountId)
	if err != nil {
		return nil, err
	}

	return post, nil
}
