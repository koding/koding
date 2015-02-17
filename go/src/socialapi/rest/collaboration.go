package rest

import "socialapi/workers/collaboration/models"

func CollaborationPing(p *models.Ping, token string) (*models.Ping, error) {
	url := "/collaboration/ping"
	res, err := sendModelWithAuth("POST", url, p, token)
	if err != nil {
		return nil, err
	}

	return res.(*models.Ping), nil
}
