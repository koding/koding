package helpers

import (
	"socialapi/models"
	"socialapi/request"

	"github.com/koding/bongo"
	"github.com/koding/runner"
)

func FetchMessageIdsByChannelId(channelId int64, q *request.Query) ([]int64, error) {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"channel_id": channelId,
		},
		Pluck:      "message_id",
		Pagination: *bongo.NewPagination(q.Limit, q.Skip),
		Sort: map[string]string{
			"added_at": "DESC",
		},
	}

	var messageIds []int64
	if err := models.NewChannelMessageList().Some(&messageIds, query); err != nil {
		return nil, err
	}

	if messageIds == nil {
		return make([]int64, 0), nil
	}

	return messageIds, nil
}

func FetchMessagesByIds(messageIds []int64, err error) ([]models.ChannelMessage, error) {
	if err != nil {
		return make([]models.ChannelMessage, 0), err
	}

	if len(messageIds) == 0 {
		return make([]models.ChannelMessage, 0), nil
	}

	channelMessages, err := models.NewChannelMessage().FetchByIds(messageIds)
	if err != nil {
		return nil, err
	}

	return channelMessages, nil
}

func ConvertMessagesToMessageContainers(messages []models.ChannelMessage, accountId int64) ([]*models.ChannelMessageContainer, error) {
	if messages == nil {
		return make([]*models.ChannelMessageContainer, len(messages)), nil
	}

	containers := make([]*models.ChannelMessageContainer, len(messages))
	if len(messages) == 0 {
		return containers, nil
	}

	decorateContainers(containers, messages, accountId)

	return containers, nil
}

func decorateContainers(containers []*models.ChannelMessageContainer, messages []models.ChannelMessage, accountId int64) {
	log := runner.MustGetLogger()
	var err error
	for i, message := range messages {
		d := models.NewChannelMessage()
		*d = message

		containers[i], err = d.BuildEmptyMessageContainer()
		if err != nil {
			log.Error("Could not create message container for message %d: %s", containers[i].Message.Id, err)
			continue
		}
	}
}
