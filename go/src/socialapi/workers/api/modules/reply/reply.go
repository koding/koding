package reply

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"

	"github.com/jinzhu/gorm"
)

func Create(u *url.URL, h http.Header, reply *models.ChannelMessage) (int, http.Header, interface{}, error) {
	parentId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	// first create reply as a message
	reply.Type = models.ChannelMessage_TYPE_REPLY


	if err := reply.Create(); err != nil {
		// todo this should be internal server error
		return helpers.NewBadRequestResponse()
	}

	// then add this message as a reply to a parent message
	mr := models.NewMessageReply()
	mr.MessageId = parentId
	mr.ReplyId = reply.Id
	mr.CreatedAt = reply.CreatedAt
	if err := mr.Create(); err != nil {
		// todo this should be internal server error
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(reply)
}

func Delete(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	parentId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	if parentId == 0 {
		// todo add proper logging
		return helpers.NewBadRequestResponse()
	}

	replyId, err := helpers.GetURIInt64(u, "replyId")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	if replyId == 0 {
		// todo add proper logging
		return helpers.NewBadRequestResponse()
	}

	// first delete the connection between message and the reply
	mr := models.NewMessageReply()
	mr.MessageId = parentId
	mr.ReplyId = replyId
	if err := mr.Delete(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	// then delete the message itself
	reply := models.NewChannelMessage()
	reply.Id = replyId
	if err := reply.Delete(); err != nil {
		return helpers.NewBadRequestResponse()
	}

	// yes it is deleted but not removed completely from our system
	return helpers.NewDeletedResponse()
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	messageId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	reply := models.NewMessageReply()
	reply.MessageId = messageId

	replies, err := reply.List()
	if err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse()
	}

	return helpers.NewOKResponse(replies)
}
