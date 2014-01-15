package rollbar

import (
	"encoding/json"
)

type DeployService struct {
	C *Client
}

type DeployResponse struct {
	Err    int           `json:"err"`
	Result DeploysResult `json:"result"`
}

type DeploysResult struct {
	Page    int      `json:"page"`
	Deploys []Deploy `json:"deploys"`
}

type Deploy struct {
	Id         int   `json:"id"`
	ProjectId  int   `json:"project_id"`
	StartTime  int64 `json:"start_time"`
	FinishTime int64 `json:"finish_time"`
}

func (d *DeployService) GetDeploys() (*DeployResponse, error) {
	var response = &DeployResponse{}

	var body, err = d.C.Request("GET", "deploys")
	if err != nil {
		return response, err
	}

	defer body.Close()

	err = json.NewDecoder(body).Decode(&response)
	if err != nil {
		return response, err
	}

	return response, nil
}
