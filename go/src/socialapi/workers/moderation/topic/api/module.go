package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
)

func CreateLink(u *url.URL, h http.Header, req *models.ChannelLink) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		req.Follow(rootId),
	)
}

func GetLink(u *url.URL, h http.Header, req *models.ChannelLink) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		req.Follow(rootId),
	)
}

func UnLink(u *url.URL, h http.Header, req *models.ChannelLink) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		req.Follow(rootId),
	)
}

func Blacklist(u *url.URL, h http.Header, req *models.ChannelLink) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		req.Follow(rootId),
	)
}
