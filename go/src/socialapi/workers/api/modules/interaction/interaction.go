package interaction

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/request"
	"socialapi/workers/common/response"
)

func prepareInteraction(u *url.URL, req *models.Interaction) (*models.Interaction, error) {
	messageId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return nil, errors.New("Couldnt get mesage id from URI")
	}

	if req.AccountId == 0 {
		return nil, errors.New("AccountId is not set")
	}

	interactionType := u.Query().Get("type")
	//if interaction is not in the allowed interations
	if _, ok := models.AllowedInteractions[interactionType]; !ok {
		return nil, errors.New(fmt.Sprintf("interaction not allowed - %s", interactionType))
	}

	req.MessageId = messageId
	req.TypeConstant = interactionType
	return req, nil
}

func Add(u *url.URL, h http.Header, req *models.Interaction) (int, http.Header, interface{}, error) {
	var err error
	req, err = prepareInteraction(u, req)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// to-do check uniqness before saving
	if err := req.Create(); err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(req)
}

func Delete(u *url.URL, h http.Header, req *models.Interaction) (int, http.Header, interface{}, error) {
	var err error
	req, err = prepareInteraction(u, req)
	if err != nil {
		return response.NewBadRequest(err)
	}

	if err := req.Delete(); err != nil {
		return response.NewBadRequest(err)
	}

	// yes it is deleted but not removed completely from our system
	return response.NewOK(nil)
}

func List(u *url.URL, h http.Header, _ interface{}) (int, http.Header, interface{}, error) {
	messageId, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	query := request.GetQuery(u)
	if query.Type == "" {
		query.Type = "like"
	}

	i := models.NewInteraction()
	// set message id
	i.MessageId = messageId

	list, err := i.List(query)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		models.FetchAccountOldsIdByIdsFromCache(list),
	)
}
