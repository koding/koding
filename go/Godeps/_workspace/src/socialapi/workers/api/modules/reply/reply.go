package reply

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/api/modules/helpers"
	"socialapi/workers/common/response"
)

func Create(u *url.URL, h http.Header, reply *models.ChannelMessage, c *models.Context) (int, http.Header, interface{}, error) {
	parentId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	// fetch the parent message
	parent, err := models.Cache.Message.ById(parentId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	parentChannel, err := models.Cache.Channel.ById(parent.InitialChannelId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	canOpen, err := parentChannel.CanOpen(c.Client.Account.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewAccessDenied(models.ErrCannotOpenChannel)
	}

	// first create reply as a message
	reply.TypeConstant = models.ChannelMessage_TYPE_REPLY

	// set initial channel id for message creation
	reply.InitialChannelId = parent.InitialChannelId

	reply.AccountId = c.Client.Account.Id

	if err := reply.Create(); err != nil {
		// todo this should be internal server error
		return response.NewBadRequest(err)
	}

	// then add this message as a reply to a parent message
	mr := models.NewMessageReply()
	mr.MessageId = parentId
	mr.ReplyId = reply.Id
	mr.CreatedAt = reply.CreatedAt
	mr.ClientRequestId = reply.ClientRequestId
	if err := mr.Create(); err != nil {
		// todo this should be internal server error
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		reply.BuildEmptyMessageContainer(),
	)
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
	accountId, err := request.GetURIInt64(u, "accountId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	reply := models.NewMessageReply()
	reply.MessageId = messageId

	messages, err := reply.List(request.GetQuery(u))
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		helpers.ConvertMessagesToMessageContainers(
			messages,
			accountId,
		),
	)
}
