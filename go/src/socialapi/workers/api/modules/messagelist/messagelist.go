package messagelist

import (
	"fmt"
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/workers/api/modules/helpers"
)

func List(u *url.URL, h http.Header, req *models.ChannelMessageList) (int, http.Header, interface{}, error) {
	channelId, err := helpers.GetURIInt64(u, "id")
	if err != nil {
		return helpers.NewBadRequestResponse()
	}

	fmt.Println(channelId)
	// req.Id = id
	// if err := req.Fetch(); err != nil {
	// 	if err == gorm.RecordNotFound {
	// 		return helpers.NewNotFoundResponse()
	// 	}
	// 	return helpers.NewBadRequestResponse()
	// }

	return helpers.NewOKResponse(req)
}
