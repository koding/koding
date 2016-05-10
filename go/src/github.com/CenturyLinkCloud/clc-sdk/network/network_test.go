package network_test

import (
	"encoding/json"
	"net/url"
	"strings"
	"testing"

	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/CenturyLinkCloud/clc-sdk/network"
	//"github.com/CenturyLinkCloud/clc-sdk/status"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

const respClaim = `
{
  "requestType": "blueprintOperation",
  "status": "succeeded",
  "summary": {
    "blueprintId": 92121,
    "locationId": "DC",
    "links": [
       {
         "rel": "network",
         "href": "/v2-experimental/networks/ALIAS/DC/123456",
         "id": "123456"
       }
    ]
  }
}
`

const respNetwork = `
{
    "id": "ec6ff75a0ffd4504840dab343fe41077",
    "cidr": "11.22.33.0/24",
    "description": "vlan_9999_11.22.33",
    "gateway": "11.22.33.1",
    "name": "vlan_9999_11.22.33",
    "netmask": "255.255.255.0",
    "type": "private",
    "vlan": 9999,
    "ipAddresses": [
        {
            "address": "11.22.33.12",
            "claimed": true,
            "server": "WA1ALIASAPI01",
            "type": "private"
        }
    ],
    "links": []
}
`

func TestGetNetwork(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2-experimental/networks/ALIAS/DC/ec6ff75a0ffd4504840dab343fe41077", mock.Anything).Return(nil)
	service := network.New(client)

	id := "ec6ff75a0ffd4504840dab343fe41077"
	resp, err := service.Get("DC", id)

	assert.Nil(err)
	assert.Equal(id, resp.ID)
	assert.Equal("11.22.33.1", resp.Gateway)
	assert.Equal("11.22.33.12", resp.IPAddresses[0].Address)
	client.AssertExpectations(t)
}

func NewMockClient() *MockClient {
	return &MockClient{}
}

type MockClient struct {
	mock.Mock
}

func (m *MockClient) Get(url string, resp interface{}) error {
	if strings.HasSuffix(url, "ec6ff75a0ffd4504840dab343fe41077") {
		json.Unmarshal([]byte(respNetwork), resp)
	}
	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Post(url string, body, resp interface{}) error {
	if strings.HasSuffix(url, "claim") {
		json.Unmarshal([]byte(respClaim), resp)
	}
	if strings.HasSuffix(url, "release") {
		// 204 on release
	}
	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Put(url string, body, resp interface{}) error {
	return nil
}

func (m *MockClient) Patch(url string, body, resp interface{}) error {
	return nil
}

func (m *MockClient) Delete(url string, resp interface{}) error {
	return nil
}

func (m *MockClient) Config() *api.Config {
	u, _ := url.Parse("http://localhost/v2-experimental")
	return &api.Config{
		User: api.User{
			Username: "test.user",
			Password: "s0s3cur3",
		},
		Alias:   "ALIAS",
		BaseURL: u,
	}
}
