package reply

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
	"socialapi/workers/common/request"
	"socialapi/workers/common/response"
	"time"
)

func Create(u *url.URL, h http.Header, reply *models.ChannelMessage) (int, http.Header, interface{}, error) {
	parentId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	// first create reply as a message
	reply.TypeConstant = models.ChannelMessage_TYPE_REPLY

	if err := reply.Create(); err != nil {
		// todo this should be internal server error
		return response.NewBadRequest(err)
	}

	// fetch parent
	parent := models.NewChannelMessage()
	if err := parent.ById(parentId); err != nil {
		return response.NewBadRequest(err)
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
		return response.NewBadRequest(err)
	}

	// update all channels that contains this message
	// todo move this to a worker
	updateAllContainingChannels(parent.Id)

	return response.HandleResultAndError(
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
	parentId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if parentId == 0 {
		// todo add proper logging
		return response.NewBadRequest(err)
	}

	replyId, err := request.GetURIInt64(u, "replyId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	if replyId == 0 {
		// todo add proper logging
		return response.NewBadRequest(err)
	}

	// first delete the connection between message and the reply
	mr := models.NewMessageReply()
	mr.MessageId = parentId
	mr.ReplyId = replyId
	if err := mr.Delete(); err != nil {
		return response.NewBadRequest(err)
	}

	// then delete the message itself
	reply := models.NewChannelMessage()
	reply.Id = replyId
	if err := reply.Delete(); err != nil {
		return response.NewBadRequest(err)
	}

	// yes it is deleted but not removed completely from our system
	return response.NewDeleted()
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	messageId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	reply := models.NewMessageReply()
	reply.MessageId = messageId

	return response.HandleResultAndError(
		helpers.ConvertMessagesToMessageContainers(
			reply.List(
				request.GetQuery(u),
			),
		),
	)
}
