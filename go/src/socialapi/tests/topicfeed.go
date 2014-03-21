package main

import "fmt"

func testTopicFeedOperations() {
	channel, err := createChannel()
	if err != nil {
		fmt.Println("error while creating channel", err)
		err = nil
	}

	channelId := channel.Id

	for i := 0; i < 3; i++ {
		channelParticipant, err := createChannelParticipant(channel.Id)
		if err != nil {
			fmt.Println("error while creating channelParticipant 1", err)
			err = nil
			return
		}

		accountId := channelParticipant.AccountId

		body := "naber #foo #bar baz"
		_, err = createPostWithBody(channelId, accountId, body)
		if err != nil {
			fmt.Println("error while creating post", err)
			err = nil
		}
	}
}
