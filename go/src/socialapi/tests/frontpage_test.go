package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"testing"

	"github.com/koding/runner"
)

var (
	PARTICIPANT_COUNT = 4
)

func TestFrontpageListingOperations(t *testing.T) {

	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	testFrontpageOperations()
}

func testFrontpageOperations() {
	var accounts []*models.Account
	for i := 0; i < 2; i++ {
		account, err := models.CreateAccountInBothDbs()
		if err == nil {
			accounts = append(accounts, account)
		}
	}

	for i := 0; i < len(accounts); i++ {
		_, err := populateChannelwithAccount(accounts[i].Id)
		if err != nil {
			fmt.Println(err)
			return
		}
	}

	for i := 0; i < len(accounts); i++ {
		channels, err := rest.FetchChannels(accounts[i].Id)
		if err != nil {
			fmt.Println(err)
			return
		}
		for j := 0; j < len(channels); j++ {
			fetchHistoryAndCheckMessages(channels[j].Id, accounts[i])
		}
	}
}

func fetchHistoryAndCheckMessages(channelId int64, account *models.Account) {
	ses, err := models.FetchOrCreateSession(account.Nick)
	if err != nil {
		fmt.Println(err)
		return
	}

	history, err := rest.GetHistory(
		channelId,
		&request.Query{
			AccountId: account.Id,
		},
		ses.ClientId,
	)

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

	participants, err := rest.CreateChannelParticipants(channel.Id, channel.CreatorId, PARTICIPANT_COUNT)
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

	participants, err := rest.CreateChannelParticipants(channelId, accountId, PARTICIPANT_COUNT)
	if err != nil {
		return nil, err
	}

	for i := 0; i < len(participants); i++ {
		reply, err := rest.AddReply(post.Id, participants[i].AccountId, post.InitialChannelId)
		if err != nil {
			return nil, err
		}

		// add likes to replies
		_, err = rest.AddInteraction("like", reply.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}

		// like every comment
		_, err = rest.AddInteraction("like", reply.Id, accountId)
		if err != nil {
			return nil, err
		}

		// add likes to post
		_, err = rest.AddInteraction("like", post.Id, participants[i].AccountId)
		if err != nil {
			return nil, err
		}

	}

	// like your post
	_, err = rest.AddInteraction("like", post.Id, accountId)
	if err != nil {
		return nil, err
	}

	return post, nil
}
