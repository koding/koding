package api

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
)

type Response struct {
	ApiKey string `json:"apiKey"`
}

func (h *Handler) GenerateKey(u *url.URL, header http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	var accountId int64

	if context.IsLoggedIn() {
		accountId = context.Client.Account.Id
	}

	c := models.NewChannel()
	err := c.FetchGroupChannel(context.GroupName)
	if err != nil {
		return response.NewBadRequest(err)
	}

	searchOnlyKey, err := h.generateSearchOnlyKey(c, accountId)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(&Response{ApiKey: searchOnlyKey})
}

func (h *Handler) generateSearchOnlyKey(c *models.Channel, accountId int64) (string, error) {
	tagFilter := generateTagFilters(c, accountId)

	return algoliasearch.GenerateSecuredAPIKey(h.searchOnlyKey, tagFilter)
}
func generateTagFilters(c *models.Channel, accountId int64) algoliasearch.Map {
	result := make(map[string]interface{}, 0)
	id := fmt.Sprintf("%d", c.Id)
	result[id] = generateUserToken(accountId)
	return result
}

func generateUserToken(accountId int64) string {
	return fmt.Sprintf("account-%d", accountId)
}
