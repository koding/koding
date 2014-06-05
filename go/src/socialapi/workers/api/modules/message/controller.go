package message

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"

	"github.com/jinzhu/gorm"
)

func Create(u *url.URL, h http.Header, req *models.ChannelMessage) (int, http.Header, interface{}, error) {
	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// override message type
	// all of the messages coming from client-side
	// should be marked as POST
	req.TypeConstant = models.ChannelMessage_TYPE_POST

	// set initial channel id
	req.InitialChannelId = channelId

	if err := req.Create(); err != nil {
		// todo this should be internal server error
		return helpers.NewBadRequestResponse(err)
	}

	cml := models.NewChannelMessageList()

	// override channel id
	cml.ChannelId = channelId
	cml.MessageId = req.Id
	if err := cml.Create(); err != nil {
		// todo this should be internal server error
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.HandleResultAndError(
		req.BuildEmptyMessageContainer(),
	)
}

func Delete(u *url.URL, h http.Header, req *models.ChannelMessage) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := req.ById(id); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse(err)
	}

	err = deleteSingleMessage(req, true)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	// yes it is deleted but not removed completely from our system
	return helpers.NewDeletedResponse()
}

func deleteSingleMessage(cm *models.ChannelMessage, deleteReplies bool) error {
	// first delete from all channels
	selector := map[string]interface{}{
		"message_id": cm.Id,
	}

	cml := models.NewChannelMessageList()
	if err := cml.DeleteMessagesBySelector(selector); err != nil {
		return err
	}

	// fetch interactions
	i := models.NewInteraction()
	i.MessageId = cm.Id
	interactions, err := i.FetchAll("like")
	if err != nil {
		return err
	}

	// delete interactions
	for _, interaction := range interactions {
		err := interaction.Delete()
		if err != nil {
			return err
		}
	}

	if deleteReplies {
		mr := models.NewMessageReply()
		mr.MessageId = cm.Id

		// list returns ChannelMessage
		messageReplies, err := mr.ListAll()
		if err != nil {
			return err
		}

		// delete message replies
		for _, replyMessage := range messageReplies {
			err := deleteSingleMessage(&replyMessage, false)
			if err != nil {
				return err
			}
		}
	}

	err = models.NewMessageReply().DeleteByOrQuery(cm.Id)
	if err != nil {
		return err
	}

	// delete replyMessage itself
	err = cm.Delete()
	if err != nil {
		return err
	}
	return nil
}

func Update(u *url.URL, h http.Header, req *models.ChannelMessage) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	body := req.Body
	if err := req.ById(id); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse(err)
	}

	if req.Id == 0 {
		return helpers.NewBadRequestResponse(err)
	}

	req.Body = body
	if err := req.Update(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.HandleResultAndError(
		req.BuildEmptyMessageContainer(),
	)
}

func Get(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}
	cm := models.NewChannelMessage()
	if err := cm.ById(id); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.HandleResultAndError(
		cm.BuildEmptyMessageContainer(),
	)
}

func GetWithRelated(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	cm := models.NewChannelMessage()
	if err := cm.ById(id); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse(err)
	}

	cmc, err := cm.BuildMessage(helpers.GetQuery(u))
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(cmc)
}
