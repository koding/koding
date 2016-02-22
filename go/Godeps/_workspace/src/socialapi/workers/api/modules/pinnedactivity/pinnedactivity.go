package pinnedactivity

import (
	"errors"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
)

func GetPinnedActivityChannel(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	// activity pining is disabled
	return response.NewOK(nil)

	// query := request.GetQuery(u)

	// if query.AccountId == 0 {
	// 	return response.NewBadRequest(fmt.Errorf("Account id is not set for fetching pinned activity channel"))
	// }

	// return response.HandleResultAndError(
	// 	models.EnsurePinnedActivityChannel(
	// 		query.AccountId,
	// 		query.GroupName,
	// 	),
	// )
}

func checkPinMessagePrerequisites(channel *models.Channel, pinRequest *models.PinRequest) error {
	if channel.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
		return errors.New("You can not add pinned message into this channel")
	}

	if channel.GroupName != pinRequest.GroupName {
		return errors.New("Grop name and channel group name doesnt match")
	}

	if channel.CreatorId != pinRequest.AccountId {
		return errors.New("Only owner can add new pinned message into this channel")
	}

	return nil
}

func PinMessage(u *url.URL, h http.Header, req *models.PinRequest, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		response.NewBadRequest(models.ErrNotLoggedIn)
	}

	req.AccountId = context.Client.Account.Id
	req.GroupName = context.GroupName

	if err := validatePinRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	c, err := models.EnsurePinnedActivityChannel(req.AccountId, req.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	canOpen, err := c.CanOpen(req.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewBadRequest(models.ErrCannotOpenChannel)
	}

	if err := checkPinMessagePrerequisites(c, req); err != nil {
		return response.NewBadRequest(err)
	}

	cm := models.NewChannelMessage()
	cm.Id = req.MessageId
	return response.HandleResultAndError(
		c.EnsureMessage(cm, true),
	)
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	// activity pining is disabled
	return response.NewOK(nil)

	// query := request.GetQuery(u)

	// if query.AccountId == 0 {
	// 	return response.NewBadRequest(errors.New("Account id is not set for fetching pinned activities"))
	// }

	// c, err := models.EnsurePinnedActivityChannel(query.AccountId, query.GroupName)
	// if err != nil {
	// 	return response.NewBadRequest(err)
	// }

	// if c.CreatorId != query.AccountId {
	// 	return response.NewBadRequest(errors.New("Only owner can list pinned messages"))
	// }

	// cml := models.NewChannelMessageList()
	// cml.ChannelId = c.Id
	// return response.HandleResultAndError(cml.List(query, true))
}

func UnpinMessage(u *url.URL, h http.Header, req *models.PinRequest, context *models.Context) (int, http.Header, interface{}, error) {
	if !context.IsLoggedIn() {
		response.NewBadRequest(models.ErrNotLoggedIn)
	}

	req.AccountId = context.Client.Account.Id
	req.GroupName = context.GroupName

	if err := validatePinRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	c, err := models.EnsurePinnedActivityChannel(req.AccountId, req.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := checkPinMessagePrerequisites(c, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		c.RemoveMessage(req.MessageId),
	)
}

func Glance(u *url.URL, h http.Header, req *models.PinRequest, context *models.Context) (int, http.Header, interface{}, error) {
	if err := validatePinRequest(req); err != nil {
		return response.NewBadRequest(err)
	}

	req.AccountId = context.Client.Account.Id
	req.GroupName = context.GroupName

	c, err := models.EnsurePinnedActivityChannel(req.AccountId, req.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	canOpen, err := c.CanOpen(req.AccountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if !canOpen {
		return response.NewBadRequest(models.ErrCannotOpenChannel)
	}

	if err := checkPinMessagePrerequisites(c, req); err != nil {
		return response.NewBadRequest(err)
	}

	cml, err := c.FetchMessageList(req.MessageId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	cml.Glance()
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(cml)
}

func validatePinRequest(req *models.PinRequest) error {
	if req.MessageId == 0 {
		return errors.New("Message id is not set")
	}

	if req.AccountId == 0 {
		return errors.New("Account id is not set")
	}

	if req.GroupName == "" {
		return errors.New("Group name is not set")
	}

	return nil
}
