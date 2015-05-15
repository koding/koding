package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"socialapi/request"

	"github.com/google/go-querystring/query"
)

// CreateLink creates a link between two channels
func CreateLink(rootId, leafId int64, token string) (*models.ChannelLink, error) {
	data := &models.ChannelLink{RootId: rootId, LeafId: leafId}
	url := fmt.Sprintf("/moderation/channel/%d/link", rootId)
	cl, err := sendModelWithAuth("POST", url, data, token)
	if err != nil {
		return nil, err
	}

	return cl.(*models.ChannelLink), nil
}

// GetLinks retunrs leaves of the given root channel
func GetLinks(rootId int64, q *request.Query, token string) ([]models.Channel, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("/moderation/channel/%d/link?%s", rootId, v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	var link []models.Channel
	err = json.Unmarshal(res, &link)
	if err != nil {
		return nil, err
	}

	return link, nil
}

// Unlink removes the link between two channels
func UnLink(rootId, leafId int64, token string) error {
	url := fmt.Sprintf("/moderation/channel/%d/link/%d", rootId, leafId)
	_, err := sendRequestWithAuth("DELETE", url, nil, token)
	return err
}

// BlackList deletes the channel and blocks it from re-creation as a channel
func BlackList(rootId, leafId int64, token string) error {
	data := &models.ChannelLink{RootId: rootId, LeafId: leafId}
	url := "/moderation/channel/blacklist"
	_, err := sendModelWithAuth("POST", url, data, token)
	if err != nil {
		return err
	}

	return nil
}

// GetRoot gets the root channel of the channel
func GetRoot(leafId int64, q *request.Query, token string) (*models.Channel,error) {
  v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("/moderation/channel/root/%d?%s", leafId, v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}
	
	cc := models.NewChannelContainer()
	err = json.Unmarshal(res, cc)
	if err != nil {
		return nil, err
	}

	return cc.Channel, nil
}