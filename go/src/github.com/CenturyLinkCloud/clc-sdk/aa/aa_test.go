package aa_test

import (
	"encoding/json"
	"net/url"
	"strings"
	"testing"

	"github.com/CenturyLinkCloud/clc-sdk/aa"
	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGetAAPolicy(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/antiAffinityPolicies/test/12345", mock.Anything).Return(nil)
	service := aa.New(client)
	id := "12345"
	resp, err := service.Get(id)

	assert.Nil(err)
	assert.Equal(id, resp.ID)
	client.AssertExpectations(t)
}

func TestGetAllAAPolicy(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/antiAffinityPolicies/test", mock.Anything).Return(nil)
	service := aa.New(client)

	resp, err := service.GetAll()

	assert.Nil(err)
	assert.Equal(2, len(resp.Items))
	client.AssertExpectations(t)
}

func TestCreateAAPolicy(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/antiAffinityPolicies/test", mock.Anything, mock.Anything).Return(nil)
	service := aa.New(client)
	name := "aa1"
	location := "dc1"

	resp, err := service.Create(name, location)

	assert.Nil(err)
	assert.Equal(name, resp.Name)
	assert.Equal(location, resp.Location)
	assert.NotEmpty(resp.ID)
	assert.NotEmpty(resp.Links)
	client.AssertExpectations(t)
}

func TestUpdateAAPolicy(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Put", "http://localhost/v2/antiAffinityPolicies/test/12345", mock.Anything, mock.Anything).Return(nil)
	service := aa.New(client)
	id := "12345"
	name := "aa1"

	resp, err := service.Update(id, name)

	assert.Nil(err)
	assert.Equal(name, resp.Name)
	client.AssertExpectations(t)
}

func TestDeleteAAPolicy(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Delete", "http://localhost/v2/antiAffinityPolicies/test/12345", nil).Return(nil)
	service := aa.New(client)

	err := service.Delete("12345")

	assert.Nil(err)
	client.AssertExpectations(t)
}

func NewMockClient() *MockClient {
	return &MockClient{}
}

type MockClient struct {
	mock.Mock
}

func (m *MockClient) Get(url string, resp interface{}) error {
	if strings.HasSuffix(url, "test") {
		json.Unmarshal([]byte(`{"items":[{"id":"12345","name":"aa1","location":"dc1","links":[{"rel":"self","href":"/v2/antiAffinityPolicies/test/12345","verbs":["GET","DELETE","PUT"]}]},{"id":"67890","name":"aa2","location":"dc2","links":[{"rel":"self","href":"/v2/antiAffinityPolicies/test/67890","verbs":["GET","DELETE","PUT"]}]}],"links":[{"rel":"self","href":"/v2/antiAffinityPolicies/test","verbs":["GET","POST"]}]}`), resp)
	}

	if strings.HasSuffix(url, "12345") {
		json.Unmarshal([]byte(`{"id":"12345","name":"aa1","location":"dc1","links":[{"rel":"self","href":"/v2/antiAffinityPolicies/test/12345","verbs":["GET","DELETE","PUT"]}]}`), resp)
	}
	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Post(url string, body, resp interface{}) error {
	json.Unmarshal([]byte(`{"id":"12345","name":"aa1","location":"dc1","links":[{"rel":"self","href":"/v2/antiAffinityPolicies/test/12345","verbs":["GET","DELETE","PUT"]}]}`), resp)
	args := m.Called(url, body, resp)
	return args.Error(0)
}

func (m *MockClient) Put(url string, body, resp interface{}) error {
	json.Unmarshal([]byte(`{"id":"12345","name":"aa1","location":"dc1","links":[{"rel":"self","href":"/v2/antiAffinityPolicies/test/12345","verbs":["GET","DELETE","PUT"]}]}`), resp)
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
