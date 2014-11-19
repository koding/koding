package rest

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"socialapi/request"

	"github.com/google/go-querystring/query"
)

func FetchChannelPermissions(channelId int64, q *request.Query, token string) (*models.PermissionResponse, error) {
	v, err := query.Values(q)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("/permission/channel/%d?%s", channelId, v.Encode())
	res, err := sendRequestWithAuth("GET", url, nil, token)
	if err != nil {
		return nil, err
	}

	var permissions models.PermissionResponse
	err = json.Unmarshal(res, &permissions)
	if err != nil {
		return nil, err
	}

	return &permissions, nil
}

func UpdatePermission(p *models.Permission, token string) (*models.Permission, error) {
	url := fmt.Sprintf("/permission/%d", p.Id)
	res, err := sendModelWithAuth("POST", url, p, token)
	if err != nil {
		return nil, err
	}

	return res.(*models.Permission), nil
}

func CreatePermission(p *models.Permission, token string) (*models.Permission, error) {
	url := "/permission"
	res, err := sendModelWithAuth("POST", url, p, token)
	if err != nil {
		return nil, err
	}

	return res.(*models.Permission), nil
}

func DeletePermission(permissionId int64, token string) error {
	url := fmt.Sprintf("/permission/%d", permissionId)
	_, err := sendRequestWithAuth("DELETE", url, nil, token)
	if err != nil {
		return err
	}

	return nil
}
