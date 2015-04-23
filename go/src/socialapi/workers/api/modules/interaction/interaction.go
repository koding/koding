package interaction

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"

	"github.com/koding/bongo"
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
		return nil, fmt.Errorf("interaction not allowed - %s", interactionType)
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

func ListInteractedMessages(u *url.URL, h http.Header, _ interface{}, c *models.Context) (int, http.Header, interface{}, error) {

	// get query
	query := request.GetQuery(u)

	id, err := request.GetURIInt64(u, "id")
	if err != nil {
		return response.NewBadRequest(err)
	}

	query.AccountId = id

	if query.Type == "" {
		query.Type = models.Interaction_TYPE_LIKE
	}

	// find the group channel id
	ch := models.NewChannel()
	selector := map[string]interface{}{
		"group_name":    c.GroupName,
		"type_constant": models.Channel_TYPE_GROUP,
	}

	if err := ch.One(bongo.NewQS(selector)); err != nil {
		return response.NewBadRequest(err)
	}

	// fetch liked messages of the account in this chanenl
	i := models.NewInteraction()
	messages, err := i.ListLikedMessages(query, ch.Id)
	if err != nil {
		return response.NewBadRequest(err)
	}

	// populate messages as channel containers, they will have many other data, like count etc
	rs := models.NewChannelMessageContainers()
	// start populating
	rs.PopulateWith(messages, query)

	return response.HandleResultAndError(rs, rs.Err())
}
