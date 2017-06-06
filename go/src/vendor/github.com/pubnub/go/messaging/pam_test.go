package messaging

import (
	"fmt"
	"github.com/stretchr/testify/assert"
	"testing"
)

// AUDIT CHANNELS
func TestPamChGenerateParamsStringAudit(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("audit", "testc", true,
		false, 4, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?auth=blah&channel=testc&%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamChGenerateParamsStringAuditNoAuth(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("audit", "testc", true, false,
		4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?channel=testc&%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamChGenerateParamsStringAuditNoChannel(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("audit", "", true, false, 4,
		"blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?auth=blah&%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamChGenerateParamsStringAuditNoAuthNoChannel(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("audit", "", true, false, 4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// GRANT CHANNELS
func TestPamChGenerateParamsStringGrant(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("grant", "testc", true, false,
		4, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&channel=testc&%s&r=1&timestamp=%s&ttl=4&uuid=%s&w=0",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no ttl
func TestPamChGenerateParamsStringGrantNoTTL(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("grant", "testc", true, false,
		-1, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&channel=testc&%s&r=1&timestamp=%s&uuid=%s&w=0",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamChGenerateParamsStringGrantNoTTLZero(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("grant", "testc", true, false,
		0, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&channel=testc&%s&r=1&timestamp=%s&ttl=0&uuid=%s&w=0",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no auth
func TestPamChGenerateParamsStringGrantNoAuth(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("grant", "testc", true, false,
		4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?channel=testc&%s&r=1&timestamp=%s&ttl=4&uuid=%s&w=0",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no channel
func TestPamChGenerateParamsStringGrantNoChannel(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("grant", "", true, false, 4,
		"blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&%s&r=1&timestamp=%s&ttl=4&uuid=%s&w=0",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no auth&channel
func TestPamChGenerateParamsStringGrantNoAuthNoChannel(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannel("grant", "", true, true, 4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?%s&r=1&timestamp=%s&ttl=4&uuid=%s&w=1",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// AUDIT CHANNEL GROUPS
func TestPamCgGenerateParamsStringAudit(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("audit", "testc", true,
		false, 4, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?auth=blah&channel-group=testc&%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamCgGenerateParamsStringAuditNoAuth(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("audit", "testc", true, false,
		4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?channel-group=testc&%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamCgGenerateParamsStringAuditNoChannelGroup(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("audit", "", true, false, 4,
		"blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?auth=blah&%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamCgGenerateParamsStringAuditNoAuthNoChannelGroup(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("audit", "", true, false, 4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/audit/sub-key/%s?%s&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// GRANT CHANNEL GROUPS
func TestPamCgGenerateParamsStringGrant(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("grant", "testc", true, false,
		4, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&channel-group=testc&m=0&%s&r=1&timestamp=%s&ttl=4&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no ttl
func TestPamCgGenerateParamsStringGrantNoTTL(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("grant", "testc", true, false,
		-1, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&channel-group=testc&m=0&%s&r=1&timestamp=%s&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

func TestPamCgGenerateParamsStringGrantNoTTLZero(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("grant", "testc", true, false,
		0, "blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&channel-group=testc&m=0&%s&r=1&timestamp=%s&ttl=0&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no auth
func TestPamCgGenerateParamsStringGrantNoAuth(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("grant", "testc", true, false,
		4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?channel-group=testc&m=0&%s&r=1&timestamp=%s&ttl=4&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no channel group
func TestPamCgGenerateParamsStringGrantNoChannelGroup(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("grant", "", true, false, 4,
		"blah")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?auth=blah&m=0&%s&r=1&timestamp=%s&ttl=4&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}

// no auth&channel group
func TestPamCgGenerateParamsStringGrantNoAuthNoChannelGroup(t *testing.T) {
	requestURL := pubnub.pamGenerateParamsForChannelGroup("grant", "", true, true, 4, "")

	assert.Equal(t, fmt.Sprintf(
		"/v1/auth/grant/sub-key/%s?m=1&%s&r=1&timestamp=%s&ttl=4&uuid=%s",
		pubnub.subscribeKey, sdkIdentificationParam, timestamp(), pubnub.GetUUID()),
		truncateSignature(requestURL), "should be equal")
}
