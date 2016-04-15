package network

import (
	"fmt"

	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/CenturyLinkCloud/clc-sdk/status"
)

func New(client api.HTTP) *Service {
	return &Service{
		client: client,
		config: client.Config(),
	}
}

type Service struct {
	client api.HTTP
	config *api.Config
}

/*
 * Networks are "claimed" and "released" from the datacenter.
 * Claim returns a status.QueuedOperation object which should be polled until status=succeeded.
 * At which point, an api.Link object with rel=network can be inspected for the ID of the claimed network.
 */

func (s *Service) List(dc string) (*[]Network, error) {
	resp := &[]Network{}
	url := fmt.Sprintf("%s/networks/%s/%s", s.config.BaseURL, s.config.Alias, dc)
	err := s.client.Get(url, resp)
	return resp, err
}

func (s *Service) Get(dc, id string) (*Network, error) {
	url := fmt.Sprintf("%s/networks/%s/%s/%s", s.config.BaseURL, s.config.Alias, dc, id)
	resp := &Network{}
	err := s.client.Get(url, resp)
	return resp, err
}

func (s *Service) GetAddresses(dc, id string) (*[]IP, error) {
	resp := &[]IP{}
	url := fmt.Sprintf("%s/networks/%s/%s/%s/ipAddresses", s.config.BaseURL, s.config.Alias, dc, id)
	err := s.client.Get(url, resp)
	return resp, err
}

func (s *Service) Claim(dc string) (*status.QueuedOperation, error) {
	resp := &status.QueuedOperation{}
	url := fmt.Sprintf("%s/networks/%s/%s/claim", s.config.BaseURL, s.config.Alias, dc)
	err := s.client.Post(url, "", resp)
	return resp, err
}

func (s *Service) Release(dc, id string) error {
	url := fmt.Sprintf("%s/networks/%s/%s/%s/release", s.config.BaseURL, s.config.Alias, dc, id)
	err := s.client.Post(url, "", nil)
	return err
}

func (s *Service) Update(dc, id, name, description string) error {
	url := fmt.Sprintf("%s/networks/%s/%s/%s", s.config.BaseURL, s.config.Alias, dc, id)
	body := fmt.Sprintf(`{"name": "%s", "description": "%s"}`, name, description)
	err := s.client.Post(url, body, nil)
	return err
}

type Network struct {
	ID          string    `json:"id"`
	CIDR        string    `json:"cidr"`
	Description string    `json:"description"`
	Gateway     string    `json:"gateway"`
	Name        string    `json:"name"`
	Netmask     string    `json:"netmask"`
	Type        string    `json:"type"`
	VLAN        int       `json:"vlan"`
	IPAddresses []IP      `json:"ipAddresses"`
	Links       api.Links `json:"links"`
}

type IP struct {
	Address string `json:"address"`
	Claimed bool   `json:"claimed"`
	Server  string `json:"server"`
	Type    string `json:"type"` // private | virtual | publicMapped
}
