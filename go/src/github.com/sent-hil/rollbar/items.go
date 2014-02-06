package rollbar

import (
	"encoding/json"
	"fmt"
)

type ItemsService struct {
	C *Client
}

type ItemsResponse struct {
	Err    int         `json:"err"`
	Result ItemsResult `json:"result"`
}

type SingleItemResponse struct {
	Err    int  `json:"err"`
	Result Item `json:"result"`
}

type ItemsResult struct {
	Page  int    `json:"page"`
	Items []Item `json:"items"`
}

type Item struct {
	Id                       int    `json:"id"`
	ProjectId                int    `json:"project_id"`
	Title                    string `json:"title"`
	LastOccurrenceId         int    `json:"last_occurrence_id"`
	LastOccurrenceTimestamp  int64  `json:"last_occurrence_timestamp"`
	TotalOccurrences         int    `json:"total_occurrences"`
	FirstOccurrenceId        int    `json:"first_occurrence_id"`
	FirstOccurrenceTimestamp int64  `json:"first_occurrence_timestamp"`
	Status                   string `json:"status"`
	Level                    string `json:"level"`
}

func (i *ItemsService) All() (*ItemsResponse, error) {
	response := &ItemsResponse{}

	body, err := i.C.Request("GET", "items")
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

func (i *ItemsService) GetItem(itemId int) (*SingleItemResponse, error) {
	response := &SingleItemResponse{}

	var url = fmt.Sprintf("item/%v", itemId)
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
