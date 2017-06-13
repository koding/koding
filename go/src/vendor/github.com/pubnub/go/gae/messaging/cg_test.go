package messaging

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"testing"
)

// ADD
func TestAddChannelToChannelGroup(t *testing.T) {
	url := pubnub.generateStringforCGRequest("add", "test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"?add=test_channel&%s&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}

func TestAddChannelToChannelGroupWithAuth(t *testing.T) {
	url := pubnubWithAuth.generateStringforCGRequest("add",
		"test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"?add=test_channel&auth=blah&%s&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}

// REMOVE
func TestRemoveChannelFromChannelGroup(t *testing.T) {
	url := pubnub.generateStringforCGRequest("remove", "test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"?%s&remove=test_channel&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}

func TestRemoveChannelFromChannelGroupWithAuth(t *testing.T) {
	url := pubnubWithAuth.generateStringforCGRequest("remove",
		"test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"?auth=blah&%s&remove=test_channel&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}

// LIST GROUP
func TestListChannelGroup(t *testing.T) {
	url := pubnub.generateStringforCGRequest("list_group",
		"test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"?%s&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}

func TestListChannelGroupWithAuth(t *testing.T) {
	url := pubnubWithAuth.generateStringforCGRequest("list_group",
		"test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"?auth=blah&%s&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}

// REMOVE GROUP
func TestRemoveChannelGroup(t *testing.T) {
	url := pubnub.generateStringforCGRequest("remove_group",
		"test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"/remove?%s&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}

func TestRemoveChannelGroupWithAuth(t *testing.T) {
	url := pubnubWithAuth.generateStringforCGRequest("remove_group",
		"test_cg", "test_channel")

	assert.Equal(t, url.String(),
		fmt.Sprintf("/v1/channel-registration/sub-key/demo/channel-group/test_cg"+
			"/remove?auth=blah&%s&uuid=%s",
			sdkIdentificationParam, pubnub.GetUUID()), "should be equal")
}
