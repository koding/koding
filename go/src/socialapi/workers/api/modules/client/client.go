package client

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/common/response"
	"socialapi/workers/helper"
)

const en = "en"

// Location returns the current approximate location of the requester
func Location(u *url.URL, h http.Header, c *models.Context) (int, http.Header, interface{}, error) {
	record, err := helper.MustGetGeoIPDB().City(c.Client.IP)
	if err != nil {
		return response.NewBadRequest(err)
	}

	var location string
	city := record.City.Names[en]
	country := record.Country.Names[en]

	if city != "" {
		location = fmt.Sprintf("%s, %s", city, country)
	} else {
		location = fmt.Sprintf("%s", country)
	}

	return response.NewOK(
		map[string]interface{}{
			"location": location,
		},
	)
}
