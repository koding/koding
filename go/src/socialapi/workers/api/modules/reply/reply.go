package reply

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
	"time"
)

func Create(u *url.URL, h http.Header, reply *models.ChannelMessage) (int, http.Header, interface{}, error) {
	parentId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// first create reply as a message
	reply.TypeConstant = models.ChannelMessage_TYPE_REPLY

	if err := reply.Create(); err != nil {
		// todo this should be internal server error
		return helpers.NewBadRequestResponse(err)
	}

	// fetch parent
	parent := models.NewChannelMessage()
	if err := parent.ById(parentId); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// set reply message's inital channel id from parent's
	reply.InitialChannelId = parent.InitialChannelId

	// then add this message as a reply to a parent message
	mr := models.NewMessageReply()
	mr.MessageId = parentId
	mr.ReplyId = reply.Id
	mr.CreatedAt = reply.CreatedAt
	if err := mr.Create(); err != nil {
		// todo this should be internal server error
		return helpers.NewBadRequestResponse(err)
	}

	// update all channels that contains this message
	// todo move this to a worker
	updateAllContainingChannels(parent.Id)

	return helpers.HandleResultAndError(
		reply.BuildEmptyMessageContainer(),
	)
}

// fetch all channels that parent is in
// update all channels
func updateAllContainingChannels(parentId int64) error {
	cml := models.NewChannelMessageList()
	channels, err := cml.FetchMessageChannels(parentId)
	if err != nil {
		return err
	}

	if len(channels) == 0 {
		return nil
	}

	for _, channel := range channels {
		// if channel type is group, we dont need to update group's updatedAt
		if channel.TypeConstant == models.Channel_TYPE_GROUP {
			continue
		}

		// pinned activity channel holds messages one by one
		if channel.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
			channel.UpdatedAt = time.Now().UTC()
			if err := channel.Update(); err != nil {
				// err
			}
			continue
		}

		// if channel.TypeConstant == models.Channel_TYPE_PINNED_ACTIVITY {
		err := models.NewChannelMessageList().UpdateAddedAt(channel.Id, parentId)
		if err != nil {
			// return err
		}
	}

	return nil

}

func Delete(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	parentId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if parentId == 0 {
		// todo add proper logging
		return helpers.NewBadRequestResponse(err)
	}

	replyId, err := helpers.GetURIInt64(u, "replyId")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if replyId == 0 {
		// todo add proper logging
		return helpers.NewBadRequestResponse(err)
	}

	// first delete the connection between message and the reply
	mr := models.NewMessageReply()
	mr.MessageId = parentId
	mr.ReplyId = replyId
	if err := mr.Delete(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// then delete the message itself
	reply := models.NewChannelMessage()
	reply.Id = replyId
	if err := reply.Delete(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// yes it is deleted but not removed completely from our system
	return helpers.NewDeletedResponse()
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	messageId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	reply := models.NewMessageReply()
	reply.MessageId = messageId

	return helpers.HandleResultAndError(
		helpers.ConvertMessagesToMessageContainers(
			reply.List(
				helpers.GetQuery(u),
			),
		),
	)
}
