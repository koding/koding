package client

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/helper"
)

// Location returns the current approximate location of the requester
func Location(u *url.URL, h http.Header, c *models.Context) (int, http.Header, interface{}, error) {
	record, err := helper.MustGetGeoIPDB().City(c.Client.IP)
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.NewOK(
		map[string]interface{}{
			"location": record.City.Names["en"],
		},
	)
}
