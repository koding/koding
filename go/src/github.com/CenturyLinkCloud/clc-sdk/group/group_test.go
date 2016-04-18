package group_test

import (
	"encoding/json"
	"fmt"
	"net/url"
	"strings"
	"testing"

	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/CenturyLinkCloud/clc-sdk/group"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestCreateGroup(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/groups/test", mock.Anything, mock.Anything).Return(nil)
	service := group.New(client)

	group := group.Group{
		Name:          "new",
		Description:   "my awesome group",
		ParentGroupID: "12345",
	}
	resp, err := service.Create(group)

	assert.Nil(err)
	assert.Equal(group.Name, resp.Name)
	assert.Equal(1, len(resp.Groups))
	assert.Equal(group.ParentGroupID, resp.ParentGroupID())
	client.AssertExpectations(t)
}

func TestGetGroup(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/groups/test/67890", mock.Anything).Return(nil)
	service := group.New(client)

	id := "67890"
	resp, err := service.Get(id)

	assert.Nil(err)
	assert.Equal(id, resp.ID)
	assert.Equal("12345", resp.ParentGroupID())
	assert.Equal(resp.Servers(), []string{})
	client.AssertExpectations(t)
}

func TestUpdateGroup(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Patch", "http://localhost/v2/groups/test/67890", mock.Anything, mock.Anything).Return(nil)
	service := group.New(client)

	id := "67890"
	patches := make([]api.Update, 3)
	patches[0] = group.UpdateName("foobar")
	patches[1] = group.UpdateDescription("mangled")
	patches[2] = group.UpdateParentGroupID("mangled")

	err := service.Update(id, patches...)

	assert.Nil(err)
	client.AssertExpectations(t)
}

func TestDeleteGroup(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Delete", "http://localhost/v2/groups/test/67890", mock.Anything).Return(nil)
	service := group.New(client)

	id := "67890"
	resp, err := service.Delete(id)

	assert.Nil(err)
	assert.Equal("status", resp.Rel)
	assert.NotEmpty(resp.ID)
	client.AssertExpectations(t)
}

func TestArchiveGroup(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/groups/test/67890/archive", "", mock.Anything).Return(nil)
	service := group.New(client)

	id := "67890"
	resp, err := service.Archive(id)

	assert.Nil(err)
	assert.Equal("status", resp.Rel)
	assert.Equal("wa1-12345", resp.ID)
	client.AssertExpectations(t)
}

func TestRestoreGroup(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/groups/test/67890/restore", `{"targetGroupId": "55555"}`, mock.Anything).Return(nil)
	service := group.New(client)

	id := "67890"
	resp, err := service.Restore(id, "55555")

	assert.Nil(err)
	ok, qid := resp.GetStatusID()
	assert.True(ok)
	assert.Equal("wa1-12345", qid)
	client.AssertExpectations(t)
}

// conspicuously missing
//func SetDefaults(t *testing.T) {}
//func SetHorizontalAutoscalePolicy(t *testing.T) {}

func NewMockClient() *MockClient {
	return &MockClient{}
}

type MockClient struct {
	mock.Mock
}

func (m *MockClient) Get(url string, resp interface{}) error {
	json.Unmarshal([]byte(mockGroup), resp)
	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Post(url string, body, resp interface{}) error {
	var canned string
	if strings.HasSuffix(url, "archive") {
		canned = statusResp
	} else if strings.HasSuffix(url, "restore") {
		canned = queuedResp
	} else if strings.HasSuffix(url, "/v2/groups/test") {
		canned = mockGroup
	} else {
		return fmt.Errorf("%v unmocked. add an impl", url)
	}
	json.Unmarshal([]byte(canned), resp)
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
	json.Unmarshal([]byte(`{"id":"va1-12345","rel":"status","href":"/v2/operations/test/status/va1-12345"}`), resp)
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

const mockGroup = `{"id":"67890","name":"new","description":"my awesome group","locationId":"WA1","type":"default","status":"active","groups":[{"id":"12345","name":"Parent Group Name","description":"The parent group.","locationId":"WA1","type":"default","status":"active","serversCount":0,"groups":[],"links":[{"rel":"createGroup","href":"/v2/groups/acct","verbs":["POST"]},{"rel":"createServer","href":"/v2/servers/acct","verbs":["POST"]},{"rel":"self","href":"/v2/groups/acct/12345","verbs":["GET","PATCH","DELETE"]},{"rel":"parentGroup","href":"/v2/groups/acct/12345","id":"12345"},{"rel":"defaults","href":"/v2/groups/acct/12345/defaults","verbs":["GET","POST"]},{"rel":"billing","href":"/v2/groups/acct/12345/billing"},{"rel":"archiveGroupAction","href":"/v2/groups/acct/12345/archive"},{"rel":"statistics","href":"/v2/groups/acct/12345/statistics"},{"rel":"upcomingScheduledActivities","href":"/v2/groups/acct/12345/upcomingScheduledActivities"},{"rel":"horizontalAutoscalePolicyMapping","href":"/v2/groups/acct/12345/horizontalAutoscalePolicy","verbs":["GET","PUT","DELETE"]},{"rel":"scheduledActivities","href":"/v2/groups/acct/12345/scheduledActivities","verbs":["GET","POST"]}]}],"links":[{"rel":"self","href":"/v2/groups/acct/67890"},{"rel":"parentGroup","href":"/v2/groups/acct/12345","id":"12345"},{"rel":"billing","href":"/v2/groups/acct/67890/billing"},{"rel":"archiveGroupAction","href":"/v2/groups/acct/67890/archive"},{"rel":"statistics","href":"/v2/groups/acct/67890/statistics"},{"rel":"scheduledActivities","href":"/v2/groups/acct/67890/scheduledActivities"}],"changeInfo":{"createdDate":"2012-12-17T01:17:17Z","createdBy":"user@domain.com","modifiedDate":"2014-05-16T23:49:25Z","modifiedBy":"user@domain.com"},"customFields":[]}`

const statusResp = `{"rel":"status", "href":"/v2/operations/acct/status/wa1-12345", "id":"wa1-12345"}`

const queuedResp = `{"isQueued":true, "links":[{"rel":"self", "href":"/v2/groups/acct/67890?AccountAlias=ALIAS&identifier=2a5c0b9662cf4fc8bf6180f139facdc0"}, {"rel":"status", "href":"/v2/operations/acct/status/wa1-12345", "id":"wa1-12345"}]}`
