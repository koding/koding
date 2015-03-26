package api

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
)

type Response struct {
	ApiKey string `json:"apiKey"`
}

func (h *Handler) GenerateKey(u *url.URL, header http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {

	var accountId int64
	if context.Client != nil && context.Client.Account != nil {
		accountId = context.Client.Account.Id
	}
	c, err := fetchContextChannel(context)
	if err != nil {
		return response.NewBadRequest(err)
	}

	apiKey, err := h.generateApiKey(c, accountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	r := &Response{ApiKey: apiKey}

	return response.NewOK(r)
}

func fetchContextChannel(context *models.Context) (models.Channel, error) {
	c := models.NewChannel()
	q := request.NewQuery()
	q.GroupName = context.GroupName
	q.Name = "public"
	q.Type = models.Channel_TYPE_GROUP

	return c.ByName(q)
}

func (h *Handler) generateApiKey(c models.Channel, accountId int64) (string, error) {

	tagFilter := generateTagFilters(c, accountId)

	return h.client.GenerateSecuredApiKey(h.apiKey, tagFilter)
}

func generateTagFilters(c models.Channel, accountId int64) string {
	return fmt.Sprintf("(%d,%s)", c.Id, generateUserToken(accountId))
}

func generateUserToken(accountId int64) string {
	return fmt.Sprintf("user-%d", accountId)
}
