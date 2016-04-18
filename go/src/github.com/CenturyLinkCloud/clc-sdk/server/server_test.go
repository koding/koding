package server_test

import (
	"encoding/json"
	"net/url"
	"strings"
	"testing"

	"github.com/CenturyLinkCloud/clc-sdk/api"
	"github.com/CenturyLinkCloud/clc-sdk/server"
	"github.com/CenturyLinkCloud/clc-sdk/status"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGetServer(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/servers/test/va1testserver01", mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	resp, err := service.Get(name)

	assert.Nil(err)
	assert.Equal(name, resp.Name)
	client.AssertExpectations(t)
}

func TestGetServerByUUID(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/servers/test/5404cf5ece2042dc9f2ac16ab67416bb?uuid=true", mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.Get("5404cf5ece2042dc9f2ac16ab67416bb")

	assert.Nil(err)
	assert.Equal("va1testserver01", resp.Name)
	client.AssertExpectations(t)
}

func TestGetServerCredentials(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/servers/test/va1testserver01/credentials", mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.GetCredentials("va1testserver01")

	assert.Nil(err)
	assert.Equal("user", resp.Username)
	assert.Equal("pass", resp.Password)
	client.AssertExpectations(t)
}

func TestCreateServer(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/servers/test", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	server := server.Server{
		Name:           "server",
		CPU:            1,
		MemoryGB:       1,
		GroupID:        "group",
		SourceServerID: "UBUNTU",
		Type:           "standard",
	}
	s, err := service.Create(server)
	ok, id := s.GetStatusID()

	assert.Nil(err)
	assert.True(s.IsQueued)
	assert.Equal(server.Name, s.Server)
	assert.True(ok)
	assert.NotEmpty(id)
	client.AssertExpectations(t)
}

func TestCreateServer_InvalidServer(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	service := server.New(client)

	s := server.Server{}
	_, err := service.Create(s)

	assert.NotNil(err)
	assert.Equal(err, server.ErrInvalidServer)
}

func TestUpdateServer_UpdateCPU(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	update := []api.Update{api.Update{Op: "set", Member: "cpu", Value: 1}}
	client.On("Patch", "http://localhost/v2/servers/test/va1testserver01", update, mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	resp, err := service.Update(name, server.UpdateCPU(1))

	assert.Nil(err)
	assert.Equal("status", resp.Rel)
	client.AssertExpectations(t)
}

func TestUpdateServer_UpdateMemory(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	update := []api.Update{api.Update{Op: "set", Member: "memory", Value: 1}}
	client.On("Patch", "http://localhost/v2/servers/test/va1testserver01", update, mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	resp, err := service.Update(name, server.UpdateMemory(1))

	assert.Nil(err)
	assert.Equal("status", resp.Rel)
	client.AssertExpectations(t)
}

func TestUpdateServer_UpdateCredentials(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	update := []api.Update{
		api.Update{
			Op:     "set",
			Member: "password",
			Value: struct {
				Current  string `json:"current"`
				Password string `json:"password"`
			}{
				"current",
				"new",
			},
		},
	}
	client.On("Patch", "http://localhost/v2/servers/test/va1testserver01", update, mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	resp, err := service.Update(name, server.UpdateCredentials("current", "new"))

	assert.Nil(err)
	assert.Equal("status", resp.Rel)
	client.AssertExpectations(t)
}

func TestUpdateServer_UpdateGroupAndDescription(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	update := []api.Update{
		api.Update{Op: "set", Member: "groupId", Value: "12345"},
		api.Update{Op: "set", Member: "description", Value: "new"},
	}
	client.On("Patch", "http://localhost/v2/servers/test/va1testserver01", update, mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	err := service.Edit(name, server.UpdateGroup("12345"), server.UpdateDescription("new"))

	assert.Nil(err)
	client.AssertExpectations(t)
}

func TestUpdateServer_UpdateAdditionaldisks(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	disks := []server.Disk{
		server.Disk{
			Path:   "/data1",
			SizeGB: 10,
			Type:   "partitioned",
		},
	}
	update := []api.Update{
		api.Update{Op: "set", Member: "disks", Value: disks},
	}
	client.On("Patch", "http://localhost/v2/servers/test/va1testserver01", update, mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	err := service.Edit(name, server.UpdateAdditionaldisks(disks))

	assert.Nil(err)
	client.AssertExpectations(t)
}

func TestUpdateServer_UpdateCustomfields(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	fields := []api.Customfields{
		api.Customfields{
			ID:    "deadbeef",
			Value: "abracadabra",
		},
	}
	update := []api.Update{
		api.Update{Op: "set", Member: "customFields", Value: fields},
	}
	client.On("Patch", "http://localhost/v2/servers/test/va1testserver01", update, mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	err := service.Edit(name, server.UpdateCustomfields(fields))

	assert.Nil(err)
	client.AssertExpectations(t)
}

func TestDeleteServer(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Delete", "http://localhost/v2/servers/test/va1testserver01", mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	server, err := service.Delete(name)

	assert.Nil(err)
	assert.Equal(name, server.Server)
	client.AssertExpectations(t)
}

func TestPowerState_Pause(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/pause", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.Pause, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestPowerState_On(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/powerOn", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.On, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestPowerState_Off(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/powerOff", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.Off, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestPowerState_Reboot(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/reboot", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.Reboot, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestPowerState_Reset(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/reset", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.Reset, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestPowerState_ShutDown(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/shutDown", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.ShutDown, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestPowerState_StartMaintenance(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/startMaintenance", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.StartMaintenance, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestPowerState_StopMaintenance(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/stopMaintenance", []string{"va1testserver01", "va1testserver02"}, mock.Anything).Return(nil)
	service := server.New(client)

	resp, err := service.PowerState(server.StopMaintenance, "va1testserver01", "va1testserver02")

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestAddPublicIP(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/servers/test/va1testserver01/publicIPAddresses", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	name := "va1testserver01"
	ip := server.PublicIP{}
	ip.Ports = []server.Port{server.Port{Protocol: "TCP", Port: 8080}}

	resp, err := service.AddPublicIP(name, ip)

	assert.Nil(err)
	assert.Equal("status", resp.Rel)
	client.AssertExpectations(t)
}

func TestGetPublicIP(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Get", "http://localhost/v2/servers/test/va1testserver01/publicIPAddresses/10.0.0.1", mock.Anything).Return(nil)
	service := server.New(client)

	addr := "10.0.0.1"
	name := "va1testserver01"

	resp, err := service.GetPublicIP(name, addr)

	assert.Nil(err)
	assert.Equal(addr, resp.InternalIP)
	assert.Equal(1, len(resp.Ports))
	client.AssertExpectations(t)
}

func TestUpdatePublicIP(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Put", "http://localhost/v2/servers/test/va1testserver01/publicIPAddresses/10.0.0.1", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	addr := "10.0.0.1"
	name := "va1testserver01"
	ip := server.PublicIP{}
	ip.InternalIP = addr
	ip.Ports = []server.Port{server.Port{Protocol: "TCP", Port: 443}}

	resp, err := service.UpdatePublicIP(name, addr, ip)

	assert.Nil(err)
	assert.Equal("status", resp.Rel)
	client.AssertExpectations(t)
}

func TestDeletePublicIP(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Delete", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	addr := "10.0.0.1"
	name := "va1testserver01"

	resp, err := service.DeletePublicIP(name, addr)

	assert.Nil(err)
	assert.NotEmpty(resp.ID)
	client.AssertExpectations(t)
}

func TestAddSecondaryNetwork(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/servers/test/va1testserver01/networks", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	addr := "123.456.1.1"
	name := "va1testserver01"
	net := "61a7e67908ce4bedabfdaf694a1360fe"

	resp, err := service.AddSecondaryNetwork(name, net, addr)

	assert.Nil(err)
	assert.IsType(resp, &status.Status{})
	assert.Equal(resp.ID, "2b70710dba4142dcaf3ab2de68e4f40c")
	client.AssertExpectations(t)
}

func TestArchiveServer(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/archive", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	serverA := "va1testserver01"
	serverB := "va1testserver02"
	resp, err := service.Archive(serverA, serverB)

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestRestoreServer(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/servers/test/va1testserver01/restore", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	server := "va1testserver01"
	resp, err := service.Restore(server, "12345")

	assert.Nil(err)
	assert.NotEmpty(resp.ID)
	client.AssertExpectations(t)
}

func TestCreateSnapshot(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	snapshot := server.Snapshot{Expiration: 3, Servers: []string{"va1testserver01", "va1testserver02"}}
	client.On("Post", "http://localhost/v2/operations/test/servers/createSnapshot", snapshot, mock.Anything).Return(nil)
	service := server.New(client)

	serverA := "va1testserver01"
	serverB := "va1testserver02"
	resp, err := service.CreateSnapshot(3, serverA, serverB)

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func TestDeleteSnapshot(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Delete", "http://localhost/v2/servers/test/va1testserver01/snapshots/4", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	server := "va1testserver01"
	resp, err := service.DeleteSnapshot(server, "4")

	assert.Nil(err)
	assert.NotEmpty(resp.ID)
	client.AssertExpectations(t)
}

func TestRevertSnapshot(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/servers/test/va1testserver01/snapshots/10/restore", nil, mock.Anything).Return(nil)
	service := server.New(client)

	server := "va1testserver01"
	resp, err := service.RevertSnapshot(server, "10")

	assert.Nil(err)
	assert.NotEmpty(resp.ID)
	client.AssertExpectations(t)
}

func TestExecutePackage(t *testing.T) {
	assert := assert.New(t)

	client := NewMockClient()
	client.On("Post", "http://localhost/v2/operations/test/servers/executePackage", mock.Anything, mock.Anything).Return(nil)
	service := server.New(client)

	serverA := "va1testserver01"
	serverB := "va1testserver02"
	pkg := server.Package{
		ID:     "12345",
		Params: map[string]string{"key1": "value1", "key2": "value2"},
	}
	resp, err := service.ExecutePackage(pkg, serverA, serverB)

	assert.Nil(err)
	assert.Equal(2, len(resp))
	client.AssertExpectations(t)
}

func NewMockClient() *MockClient {
	return &MockClient{}
}

type MockClient struct {
	mock.Mock
}

func (m *MockClient) Get(url string, resp interface{}) error {
	if strings.HasSuffix(url, "credentials") {
		json.Unmarshal([]byte(`{"userName":"user","password":"pass"}`), resp)
	}

	if strings.HasSuffix(url, "va1testserver01") || strings.HasSuffix(url, "?uuid=true") {
		json.Unmarshal([]byte(serverJSON), resp)
	}

	if strings.HasSuffix(url, "10.0.0.1") {
		json.Unmarshal([]byte(`{"internalIPAddress":"10.0.0.1","ports":[{"protocol":"TCP","port":80}]}`), resp)
	}

	args := m.Called(url, resp)
	return args.Error(0)
}

func (m *MockClient) Post(url string, body, resp interface{}) error {
	if strings.HasSuffix(url, "test") {
		json.Unmarshal([]byte(`{"server":"server","isQueued":true,"links":[{"rel":"status","href":"/v2/operations/alias/status/wa1-12345","id":"wa1-12345"},{"rel":"self","href":"/v2/servers/alias/8134c91a66784c6dada651eba90a5123?uuid=True","id":"8134c91a66784c6dada651eba90a5123","verbs":["GET"]}]}`), resp)
	}

	if strings.HasSuffix(url, "publicIPAddresses") || strings.HasSuffix(url, "restore") {
		json.Unmarshal([]byte(`{"id":"va1-12345","rel":"status","href":"/v2/operations/test/status/va1-12345"}`), resp)
	}

	if strings.HasSuffix(url, "networks") {
		json.Unmarshal([]byte(`{"operationId":"2b70710dba4142dcaf3ab2de68e4f40c","uri":"http://api.ctl.io/v2-experimental/operations/RSDA/status/2b70710dba4142dcaf3ab2de68e4f40c"}`), resp)
	}

	if strings.Contains(url, "operations/test/servers") {
		json.Unmarshal([]byte(`[{"server":"va1t3osserver01","isQueued":true,"links":[{"rel":"status","href":"/v2/operations/alias/status/dc1-12345","id":"dc1-12345"}]},{"server":"va1t3osserver02","isQueued":true,"links":[{"rel":"status","href":"/v2/operations/alias/status/dc1-12346","id":"dc1-12346"}]}]`), resp)
	}
	args := m.Called(url, body, resp)
	return args.Error(0)
}

func (m *MockClient) Put(url string, body, resp interface{}) error {
	if strings.Index(url, "publicIPAddresses") != -1 {
		json.Unmarshal([]byte(`{"id":"va1-12345","rel":"status","href":"/v2/operations/test/status/va1-12345"}`), resp)
	}

	args := m.Called(url, body, resp)
	return args.Error(0)
}

func (m *MockClient) Patch(url string, body, resp interface{}) error {
	if strings.HasSuffix(url, "va1testserver01") {
		json.Unmarshal([]byte(`{"id":"va1-12345","rel":"status","href":"/v2/operations/test/status/va1-12345"}`), resp)
	}
	args := m.Called(url, body, resp)
	return args.Error(0)
}

func (m *MockClient) Delete(url string, resp interface{}) error {
	if strings.HasSuffix(url, "va1testserver01") {
		json.Unmarshal([]byte(`{"server":"va1testserver01","isQueued":true,"links":[{"rel":"status","href":"/v2/operations/alias/status/wa1-12345","id":"wa1-12345"},{"rel":"self","href":"/v2/servers/alias/8134c91a66784c6dada651eba90a5123?uuid=True","id":"8134c91a66784c6dada651eba90a5123","verbs":["GET"]}]}`), resp)
	}
	if strings.HasSuffix(url, "10.0.0.1") || strings.Contains(url, "snapshot") {
		json.Unmarshal([]byte(`{"id":"va1-12345","rel":"status","href":"/v2/operations/test/status/va1-12345"}`), resp)
	}
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

var serverJSON = `{"id":"va1testserver01","name":"va1testserver01","description":"My web server","groupId":"2a5c0b9662cf4fc8bf6180f139facdc0","isTemplate":false,"locationId":"WA1","osType":"Windows 2008 64-bit","status":"active","details":{"ipAddresses":[{"internal":"10.82.131.44"},{"public":"91.14.111.101","internal":"10.82.131.45"}],"alertPolicies":[{"id":"15836e6219e84ac736d01d4e571bb950","name":"Production Web Servers - RAM","links":[{"rel":"self","href":"/v2/alertPolicies/alias/15836e6219e84ac736d01d4e571bb950"},{"rel":"alertPolicyMap","href":"/v2/servers/alias/WA1ALIASWB01/alertPolicies/15836e6219e84ac736d01d4e571bb950","verbs":["DELETE"]}]},{"id":"2bec81dd90aa4217887548c3c20d7421","name":"Production Web Servers - Disk","links":[{"rel":"self","href":"/v2/alertPolicies/alias/2bec81dd90aa4217887548c3c20d7421"},{"rel":"alertPolicyMap","href":"/v2/servers/alias/WA1ALIASWB01/alertPolicies/2bec81dd90aa4217887548c3c20d7421","verbs":["DELETE"]}]}],"cpu":2,"diskCount":1,"hostName":"WA1ALIASWB01.customdomain.com","inMaintenanceMode":false,"memoryMB":4096,"powerState":"started","storageGB":60,"disks":[{"id":"0:0","sizeGB":60,"partitionPaths":[]}],"partitions":[{"sizeGB":59.654,"path":"C:"}],"snapshots":[{"name":"2014-05-16.23:45:52","links":[{"rel":"self","href":"/v2/servers/alias/WA1ALIASWB01/snapshots/40"},{"rel":"delete","href":"/v2/servers/alias/WA1ALIASWB01/snapshots/40"},{"rel":"restore","href":"/v2/servers/alias/WA1ALIASWB01/snapshots/40/restore"}]}],"customFields":[{"id":"22f002123e3b46d9a8b38ecd4c6df7f9","name":"Cost Center","value":"IT-DEV","displayValue":"IT-DEV"},{"id":"58f83af6123846769ee6cb091ce3561e","name":"CMDB ID","value":"1100003","displayValue":"1100003"}]},"type":"standard","storageType":"standard","changeInfo":{"createdDate":"2012-12-17T01:17:17Z","createdBy":"user@domain.com","modifiedDate":"2014-05-16T23:49:25Z","modifiedBy":"user@domain.com"},"links":[{"rel":"self","href":"/v2/servers/alias/WA1ALIASWB01","id":"WA1ALIASWB01","verbs":["GET","PATCH","DELETE"]},{"rel":"group","href":"/v2/groups/alias/2a5c0b9662cf4fc8bf6180f139facdc0","id":"2a5c0b9662cf4fc8bf6180f139facdc0"},{"rel":"account","href":"/v2/accounts/alias","id":"alias"},{"rel":"billing","href":"/v2/billing/alias/estimate-server/WA1ALIASWB01"},{"rel":"statistics","href":"/v2/servers/alias/WA1ALIASWB01/statistics"},{"rel":"scheduledActivities","href":"/v2/servers/alias/WA1ALIASWB01/scheduledActivities"},{"rel":"publicIPAddresses","href":"/v2/servers/alias/WA1ALIASWB01/publicIPAddresses","verbs":["POST"]},{"rel":"alertPolicyMappings","href":"/v2/servers/alias/WA1ALIASWB01/alertPolicies","verbs":["POST"]},{"rel":"antiAffinityPolicyMapping","href":"/v2/servers/alias/WA1ALIASWB01/antiAffinityPolicy","verbs":["DELETE","PUT"]},{"rel":"cpuAutoscalePolicyMapping","href":"/v2/servers/alias/WA1ALIASWB01/cpuAutoscalePolicy","verbs":["DELETE","PUT"]},{"rel":"capabilities","href":"/v2/servers/alias/WA1ALIASWB01/capabilities"},{"rel":"credentials","href":"/v2/servers/alias/WA1ALIASWB01/credentials"},{"rel":"publicIPAddress","href":"/v2/servers/alias/WA1ALIASWB01/publicIPAddresses/91.14.111.101","id":"91.14.111.101","verbs":["GET","PUT","DELETE"]}]}`
