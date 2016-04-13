package dc_test

import (
	"encoding/json"
	"net/url"
	"strings"
	"testing"

	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/CenturyLinkCloud/clc-sdk/dc"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGetDatacenter(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/datacenters/test/dc1?groupLinks=true", mock.Anything).Return(nil)
	service := dc.New(client)

	id := "dc1"
	resp, err := service.Get(id)

	assert.Nil(err)
	assert.Equal(id, resp.ID)
}

func TestGetDatacenters(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/datacenters/test", mock.Anything).Return(nil)
	service := dc.New(client)

	resp, err := service.GetAll()

	assert.Nil(err)
	assert.Equal(1, len(resp))
	assert.Equal("dc1", resp[0].ID)
}

func NewMockClient() *MockClient {
	return &MockClient{}
}

type MockClient struct {
	mock.Mock
}

func (m *MockClient) Get(url string, resp interface{}) error {
	if strings.HasSuffix(url, "?groupLinks=true") {
		json.Unmarshal([]byte(`{"id":"dc1","name":"test datacenter","links":[{"rel":"self","href":"/v2/datacenters/test/dc1"}]}`), resp)
	}
	if strings.HasSuffix(url, "test") {
		json.Unmarshal([]byte(`[{"id":"dc1","name":"test datacenter","links":[{"rel":"self","href":"/v2/datacenters/test/dc1"}]}]`), resp)
	}

	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Post(url string, body, resp interface{}) error {
	args := m.Called(url, body, resp)
	return args.Error(0)
}

func (m *MockClient) Put(url string, body, resp interface{}) error {
	args := m.Called(url, body, resp)
	return args.Error(0)
}

func (m *MockClient) Patch(url string, body, resp interface{}) error {
	args := m.Called(url, body, resp)
	return args.Error(0)
}

func (m *MockClient) Delete(url string, resp interface{}) error {
	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Config() *api.Config {
	u, _ := url.Parse("http://localhost/v2")
	return &api.Config{
		User: api.User{
			Username: "test.user",
			Password: "s0s3cur3",
		},
		Alias:   "test",
		BaseURL: u,
	}
}
