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

	req.RootId = rootId
	return response.HandleResultAndError(req, req.Create())
}

func GetLinks(u *url.URL, h http.Header, req *models.ChannelLink) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	leafId, err := request.GetURIInt64(u, "leafId")
	if err != nil {
		return response.NewBadRequest(err)
	}
	req.RootId = rootId
	req.LeafId = leafId

	return response.HandleResultAndError(req.List(request.GetQuery(u)))
}

func UnLink(u *url.URL, h http.Header, req *models.ChannelLink) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	leafId, err := request.GetURIInt64(u, "leafId")
	if err != nil {
		return response.NewBadRequest(err)
	}
	req.RootId = rootId
	req.LeafId = leafId
	return response.HandleResultAndError(req, req.UnLink())
}

func Blacklist(u *url.URL, h http.Header, req *models.ChannelLink) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	leafId, err := request.GetURIInt64(u, "leafId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	req.RootId = rootId
	req.LeafId = leafId

	return response.HandleResultAndError(req, req.Blacklist())
}
