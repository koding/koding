package channel

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"

	"github.com/jinzhu/gorm"
)

func validateChannelRequest(c *models.Channel) error {
	if c.GroupName == "" {
		return errors.New("Group name is not set")
	}

	if c.Name == "" {
		return errors.New("Channel name is not set")
	}

	if c.CreatorId == 0 {
		return errors.New("Creator id is not set")
	}

	return nil
}

func Create(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	if req.GroupName == "" {
		req.GroupName = models.Channel_KODING_NAME
	}

	if req.PrivacyConstant == "" {
		req.PrivacyConstant = models.Channel_PRIVACY_PUBLIC
	}

	if err := validateChannelRequest(req); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := req.Create(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(req)
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	c := models.NewChannel()
	q := helpers.GetQuery(u)
	q.Type = models.Channel_TYPE_TOPIC
	channelList, err := c.List(q)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.HandleResultAndError(
		models.PopulateChannelContainers(
			channelList,
			q.AccountId,
		),
	)
}

func Search(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := helpers.GetQuery(u)
	q.Type = models.Channel_TYPE_TOPIC

	channelList, err := models.NewChannel().Search(q)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.HandleResultAndError(
		models.PopulateChannelContainers(
			channelList,
			q.AccountId,
		),
	)
}

func ByName(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := helpers.GetQuery(u)
	q.Type = models.Channel_TYPE_TOPIC

	channelList, err := models.NewChannel().ByName(q)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.HandleResultAndError(
		models.PopulateChannelContainer(
			channelList,
			q.AccountId,
		),
	)
}

func CheckParticipation(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	q := helpers.GetQuery(u)
	if q.Type == "" || q.AccountId == 0 {
		return helpers.NewBadRequestResponse(errors.New("type or accountid is not set"))
	}

	channel, err := models.NewChannel().ByName(q)
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	cp := models.NewChannelParticipant()
	cp.ChannelId = channel.Id
	cp.AccountId = q.AccountId

	// fetch participant
	err = cp.FetchParticipant()
	if err == nil {
		return helpers.NewOKResponse(cp)
	}

	// if err is not `record not found`
	// return it immediately
	if err != gorm.RecordNotFound {
		return helpers.NewBadRequestResponse(err)
	}

	// we here we have record-not-found

	// if channel type is `group` then return true
	if channel.TypeConstant == models.Channel_TYPE_GROUP {
		return helpers.NewOKResponse(true)
	}

	// return here to the client
	return helpers.NewBadRequestResponse(err)
}

func Delete(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {

	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if err := req.ById(id); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if req.TypeConstant == models.Channel_TYPE_GROUP {
		return helpers.NewBadRequestResponse(errors.New("You can not delete group channel"))
	}
	if err := req.Delete(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}
	// yes it is deleted but not removed completely from our system
	return helpers.NewDeletedResponse()
}

func Update(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}
	req.Id = id

	if req.Id == 0 {
		return helpers.NewBadRequestResponse(err)
	}

	existingOne := models.NewChannel()
	if err := existingOne.ById(id); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	if existingOne.CreatorId != req.CreatorId {
		return helpers.NewBadRequestResponse(errors.New("CreatorId doesnt match"))
	}

	// only allow purpose and name to be updated
	if req.Purpose != "" {
		existingOne.Purpose = req.Purpose
	}

	if req.Name != "" {
		existingOne.Name = req.Name
	}

	if err := req.Update(); err != nil {
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.NewOKResponse(req)
}

func Get(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	id, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse(err)
	}
	q := helpers.GetQuery(u)

	c := models.NewChannel()
	if err := c.ById(id); err != nil {
		if err == gorm.RecordNotFound {
			return helpers.NewNotFoundResponse()
		}
		return helpers.NewBadRequestResponse(err)
	}

	return helpers.HandleResultAndError(
		models.PopulateChannelContainer(*c, q.AccountId),
	)
}

func PostMessage(u *url.URL, h http.Header, req *models.Channel) (int, http.Header, interface{}, error) {
	// id, err := helpers.GetURIInt64(u, "id")
	// if err != nil {
	// 	return helpers.NewBadRequestResponse(err)
	// }

	// req.Id = id
	// // TODO - check if the user is member of the channel

	// if err := req.Fetch(); err != nil {
	// 	if err == gorm.RecordNotFound {
	// 		return helpers.NewNotFoundResponse()
	// 	}
	// 	return helpers.NewBadRequestResponse(err)
	// }

	return helpers.NewOKResponse(req)
}
