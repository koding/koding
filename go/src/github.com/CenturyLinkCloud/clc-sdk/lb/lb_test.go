package lb_test

import (
	"encoding/json"
	"net/url"
	"strings"
	"testing"

	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/CenturyLinkCloud/clc-sdk/lb"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGetLB(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345", mock.Anything).Return(nil)
	service := lb.New(client)

	id := "12345"
	resp, err := service.Get("dc1", id)

	assert.Nil(err)
	assert.Equal(id, resp.ID)
	client.AssertExpectations(t)
}

func TestGetAllLBs(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/sharedLoadBalancers/test/dc1", mock.Anything).Return(nil)
	service := lb.New(client)

	resp, err := service.GetAll("dc1")

	assert.Nil(err)
	assert.Equal(1, len(resp))
	client.AssertExpectations(t)
}

func TestCreateLB(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/sharedLoadBalancers/test/dc1", mock.Anything, mock.Anything).Return(nil)
	service := lb.New(client)

	lb := lb.LoadBalancer{
		Name:        "new",
		Description: "balancing load",
	}
	resp, err := service.Create("dc1", lb)

	assert.Nil(err)
	assert.Equal(lb.Name, resp.Name)
	assert.Equal("enabled", resp.Status)
	assert.NotEmpty(resp.ID)
	client.AssertExpectations(t)
}

func TestUpdateLB(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Put", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345", mock.Anything, nil).Return(nil)
	service := lb.New(client)

	lb := lb.LoadBalancer{
		Name:        "new",
		Description: "balancing load",
	}
	err := service.Update("dc1", "12345", lb)

	assert.Nil(err)
	client.AssertExpectations(t)
}

func TestDeleteLB(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Delete", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345", mock.Anything).Return(nil)
	service := lb.New(client)

	id := "12345"
	err := service.Delete("dc1", id)

	assert.Nil(err)
	client.AssertExpectations(t)
}

func TestGetLBPool(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345/pools/56789", mock.Anything).Return(nil)
	service := lb.New(client)

	id := "56789"
	resp, err := service.GetPool("dc1", "12345", id)

	assert.Nil(err)
	assert.Equal(id, resp.ID)
	client.AssertExpectations(t)
}

func TestGetLBPools(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345/pools", mock.Anything).Return(nil)
	service := lb.New(client)

	resp, err := service.GetAllPools("dc1", "12345")

	assert.Nil(err)
	assert.Equal(1, len(resp))
	client.AssertExpectations(t)
}

func TestCreateLBPool(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345/pools", mock.Anything, mock.Anything).Return(nil)
	service := lb.New(client)

	pool := lb.Pool{
		Port:        80,
		Method:      lb.LeastConn,
		Persistence: lb.Sticky,
	}

	resp, err := service.CreatePool("dc1", "12345", pool)

	assert.Nil(err)
	assert.Equal(pool.Port, resp.Port)
	assert.NotEmpty(resp.ID)
	client.AssertExpectations(t)
}

func TestUpdatePool(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Put", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345/pools/56789", mock.Anything, nil).Return(nil)
	service := lb.New(client)

	pool := lb.Pool{
		Method:      lb.LeastConn,
		Persistence: lb.Sticky,
	}
	err := service.UpdatePool("dc1", "12345", "56789", pool)

	assert.Nil(err)
	client.AssertExpectations(t)
}

func TestDeleteLBPool(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Delete", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345/pools/56789", mock.Anything).Return(nil)
	service := lb.New(client)

	id := "56789"
	err := service.DeletePool("dc1", "12345", id)

	assert.Nil(err)
	client.AssertExpectations(t)
}
func TestGetAllNodes(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345/pools/56789/nodes", mock.Anything).Return(nil)
	service := lb.New(client)

	resp, err := service.GetAllNodes("dc1", "12345", "56789")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestUpdateNodes(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Put", "http://localhost/v2/sharedLoadBalancers/test/dc1/12345/pools/56789/nodes", mock.Anything, nil).Return(nil)
	service := lb.New(client)

	node := lb.Node{
		IPaddress:   "10.0.0.0",
		PrivatePort: 8080,
	}
	err := service.UpdateNodes("dc1", "12345", "56789", node)

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
	if strings.HasSuffix(url, "12345") {
		json.Unmarshal([]byte(`{"id":"12345","name":"new","description":"balancing load","ipAddress":"10.10.10.10","status":"enabled","pools":[],"links":[{"rel":"self","href":"/v2/sharedLoadBalancers/test/dc1/12345","verbs":["GET","PUT","DELETE"]},{"rel":"pools","href":"/v2/sharedLoadBalancers/test/dc1/12345/pools","verbs":["GET","POST"]}]}`), resp)
	} else if strings.HasSuffix(url, "56789") {
		json.Unmarshal([]byte(`{"id":"56789","port":80,"method":"leastConnection","persistence":"standard","links":[{"rel":"self","href":"/v2/sharedLoadBalancers/t3bk/va1/12345/pools/56789","verbs":["GET","PUT","DELETE"]},{"rel":"nodes","href":"/v2/sharedLoadBalancers/t3bk/va1/12345/pools/56789/nodes","verbs":["GET","PUT"]}]}`), resp)
	} else if strings.HasSuffix(url, "nodes") {
		json.Unmarshal([]byte(`[{"status":"enabled","ipAddress":"10.11.12.13","privatePort":80},{"status":"enabled","ipAddress":"10.11.12.14","privatePort":80}]`), resp)
	} else if strings.Contains(url, "pools") {
		json.Unmarshal([]byte(`[{"id":"56789","port":80,"method":"leastConnection","persistence":"standard","links":[{"rel":"self","href":"/v2/sharedLoadBalancers/t3bk/va1/12345/pools/56789","verbs":["GET","PUT","DELETE"]},{"rel":"nodes","href":"/v2/sharedLoadBalancers/t3bk/va1/12345/pools/56789/nodes","verbs":["GET","PUT"]}]}]`), resp)
	} else {
		json.Unmarshal([]byte(`[{"id":"12345","name":"new","description":"balancing load","ipAddress":"10.10.10.10","status":"enabled","pools":[],"links":[{"rel":"self","href":"/v2/sharedLoadBalancers/test/dc1/12345","verbs":["GET","PUT","DELETE"]},{"rel":"pools","href":"/v2/sharedLoadBalancers/test/dc1/12345/pools","verbs":["GET","POST"]}]}]`), resp)
	}

	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Post(url string, body, resp interface{}) error {
	if strings.HasSuffix(url, "pools") {
		json.Unmarshal([]byte(`{"id":"56789","port":80,"method":"leastConnection","persistence":"sticky","nodes":[],"links":[{"rel":"self","href":"/v2/sharedLoadBalancers/test/dc1/12345/pools/56789","verbs":["GET","PUT","DELETE"]},{"rel":"nodes","href":"/v2/sharedLoadBalancers/test/dc1/12345/pools/56789/nodes","verbs":["GET","PUT"]}]}`), resp)
	} else {
		json.Unmarshal([]byte(`{"id":"12345","name":"new","description":"balancing load","ipAddress":"10.10.10.10","status":"enabled","pools":[],"links":[{"rel":"self","href":"/v2/sharedLoadBalancers/test/dc1/12345","verbs":["GET","PUT","DELETE"]},{"rel":"pools","href":"/v2/sharedLoadBalancers/test/dc1/12345/pools","verbs":["GET","POST"]}]}`), resp)
	}
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
