package rollbar

import (
	"encoding/json"
	"fmt"
)

type InstanceService struct {
	C *Client
}

type InstanceResponse struct {
	Err    int            `json:"err"`
	Result InstanceResult `json:"result"`
}

type InstanceResult struct {
	Page      int        `json:"page"`
	Instances []Instance `json:"instances"`
}

type Instance struct {
	Id        int `json:"id"`
	ProjectId int `json:"project_id"`
	Timestamp int `json:"timestamp"`
}

func (i *InstanceService) GetByItem(itemId int) (*InstanceResponse, error) {
	response := &InstanceResponse{}

	url := fmt.Sprintf("item/%v/instances", itemId)
	body, err := i.C.Request("GET", url)
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
