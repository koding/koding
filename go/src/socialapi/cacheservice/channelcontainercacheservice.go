package cacheservice

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
)

// ChannelContainerService is responsible for loading channel containers.
type ChannelContainerService struct{}

func NewChannelContainerService() *ChannelContainerService {
	return &ChannelContainerService{}
}

func (c *ChannelContainerService) Getter(id int64) (string, error) {
	data, err := models.NewChannelContainer().ById(id)
	if err != nil {
		return "", err
	}

	d, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return string(d), nil
}

func (c *ChannelContainerService) Setter(id int64, data interface{}) (string, error) {
	d, err := json.Marshal(data)
	if err != nil {
		return "", err
	}

	return string(d), nil
}

func (c *ChannelContainerService) Get(id int64) (*models.ChannelContainer, error) {
	i, err := Get(c, id)
	if err != nil {
		return nil, err
	}

	if i == "" {
		return nil, nil
	}

	var container models.ChannelContainer

	return &container, json.Unmarshal([]byte(i), &container)
}

func (c *ChannelContainerService) Set(id int64, data *models.ChannelContainer) error {
	if err := Set(c, id, data); err != nil {
		return err
	}

	return nil
}

func (c *ChannelContainerService) Prefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channel", id)
}
