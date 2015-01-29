package api

import (
	"net/http"
	"net/url"
	"socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/response"
)

// CreateLink creates a new link between two channels, root and leaf id should
// be given in the request
func CreateLink(u *url.URL, h http.Header, req *models.ChannelLink, context *models.Context) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	req.RootId = rootId

	return response.HandleResultAndError(req, req.Create())
}

// GetLinks returns the leaves of a root channel
func GetLinks(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	req := &models.ChannelLink{}
	if err := prepareRequest(u, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(
		req.List(request.GetQuery(u)),
	)
}

// Unlink removes the connection between
func UnLink(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	req := &models.ChannelLink{}
	if err := prepareRequest(u, req); err != nil {
		return response.NewBadRequest(err)
	}

	return response.HandleResultAndError(req, req.UnLink())
}

// Blacklist remove the channel from system completely, it shouldnt have any
// leaf channels in order to be blacklisted
func Blacklist(u *url.URL, h http.Header, _ interface{}, context *models.Context) (int, http.Header, interface{}, error) {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return response.NewBadRequest(err)
	}

	req := models.ChannelLink{
		RootId: rootId,
	}

	return response.HandleResultAndError(req, req.Blacklist())
}

// prepareRequest read the parameters from url and sets them into struct
func prepareRequest(u *url.URL, req *models.ChannelLink) error {
	rootId, err := request.GetURIInt64(u, "rootId")
	if err != nil {
		return err
	}

	leafId, err := request.GetURIInt64(u, "leafId")
	if err != nil {
		return err
	}

	req.RootId = rootId
	req.LeafId = leafId

	return nil
}
