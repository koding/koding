package messaging

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSuccessResponseBytes(t *testing.T) {
	assert := assert.New(t)

	assert.Equal(`[["hello"], "123", "hey"]`, string(successResponse{
		Data:      []byte(`"hello"`),
		Channel:   "hey",
		Source:    "",
		Timetoken: "123",
		Type:      channelResponse,
		Presence:  false,
	}.Bytes()))

	assert.Equal(`[[2], "123", "hey"]`, string(successResponse{
		Data:      []byte(`2`),
		Channel:   "hey-pnpres",
		Source:    "",
		Timetoken: "123",
		Type:      channelResponse,
		Presence:  false,
	}.Bytes()))

	assert.Equal(`[[false], "123", "world", "news"]`, string(successResponse{
		Data:      []byte(`false`),
		Channel:   "world",
		Source:    "news",
		Timetoken: "123",
		Type:      channelGroupResponse,
		Presence:  false,
	}.Bytes()))

	assert.Equal(`[[false], "0", "news.world", "news.*"]`, string(successResponse{
		Data:      []byte(`false`),
		Channel:   "news.world",
		Source:    "news.*",
		Timetoken: "0",
		Type:      wildcardResponse,
		Presence:  false,
	}.Bytes()))
}
