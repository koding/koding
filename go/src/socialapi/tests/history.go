package main

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

func testHistoryOperations() {
	channel, err := createChannel()
	if err != nil {
		fmt.Println("error while creating channel", err)
		err = nil
	}

	CHANNEL_ID = channel.Id

	for i := 0; i < 10; i++ {
		channelParticipant, err := createChannelParticipant(channel.Id)
		if err != nil {
			fmt.Println("error while creating channelParticipant 1", err)
			err = nil
			return
		}

		ACCOUNT_ID = channelParticipant.AccountId

		_, err = createPost(CHANNEL_ID, ACCOUNT_ID)
		if err != nil {
			fmt.Println("error while creating post", err)
			err = nil
		}

		history, err := getHistory(CHANNEL_ID, ACCOUNT_ID)
		if err != nil {
			fmt.Println("Error while getting the history", err)
		}
		if history == nil {
			fmt.Print("history is nil")
			return
		}
		if len(history.MessageList) != i+1 {
			fmt.Println("history length is not OK!", len(history.MessageList), i+1)
		}
	}

}

func getHistory(channelId, accountId int64) (*models.HistoryResponse, error) {
	url := fmt.Sprintf("/channel/%d/history?accountId=%d", channelId, accountId)
	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var history models.HistoryResponse
	err = json.Unmarshal(res, &history)
	if err != nil {
		return nil, err
	}

	return &history, nil
}
