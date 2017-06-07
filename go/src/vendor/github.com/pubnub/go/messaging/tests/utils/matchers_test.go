package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

var matcher = &PubnubMatcher{
	skipFields: []string{},
}

func TestUrlsEqual(t *testing.T) {
	assert.True(t, matcher.MatchUrlStrings(
		"http://foo.bar/subscribe/subkey/ch1,ch2/asdf/qwer?zxcv=asdf",
		"http://foo.bar/subscribe/subkey/ch1,ch2/asdf/qwer?zxcv=asdf"))
}

func TestUrlParthsEqual(t *testing.T) {
	assert.True(t, matcher.MatchUrlStrings(
		"/subscribe/subkey/ch1,ch2/asdf/qwer?zxcv=asdf",
		"/subscribe/subkey/ch1,ch2/asdf/qwer?zxcv=asdf"))
}

func TestUrlsNotEqual(t *testing.T) {
	assert.False(t, matcher.MatchUrlStrings(
		"http://foo.bar/subscribe/subkey/ch1,ch2/asdf/qwer?zxcv=asdf",
		"http://foo.bar/subscribe/subkey/ch1,ch2/zzzz/qwer?zxcv=asdf"))
}

func TestUrlPathsNotEqual(t *testing.T) {
	assert.False(t, matcher.MatchUrlStrings(
		"/subscribe/subkey/ch1,ch2/asdf/qwer?zxcv=asdf",
		"/subscribe/subkey/ch1,ch2/zzzz/qwer?zxcv=asdf"))
}

func TestUrlsMixedChannelsEqual(t *testing.T) {
	assert.True(t, matcher.MatchUrlStrings(
		"http://foo.bar/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf",
		"http://foo.bar/subscribe/subkey/ch2,ch1,ch3/asdf/qwer?zxcv=asdf"))
}

func TestUrlPathsMixedChannelsEqual(t *testing.T) {
	assert.True(t, matcher.MatchUrlStrings(
		"/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf",
		"/subscribe/subkey/ch2,ch1,ch3/asdf/qwer?zxcv=asdf"))
}

func TestUrlsMixedChannelsNotEqual(t *testing.T) {
	assert.False(t, matcher.MatchUrlStrings(
		"http://foo.bar/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf",
		"http://foo.bar/subscribe/subkey/ch2,ch4,ch3/asdf/qwer?zxcv=asdf"))
}

func TestUrlPathsMixedChannelsNotEqual(t *testing.T) {
	assert.False(t, matcher.MatchUrlStrings(
		"/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf",
		"/subscribe/subkey/ch2,ch4,ch3/asdf/qwer?zxcv=asdf"))
}

func TestUrlsMixedChannelsAndChannelGroupsEqual(t *testing.T) {
	assert.True(t, matcher.MatchUrlStrings(
		"http://foo.bar/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf&channel-group=g5,g6,g4",
		"http://foo.bar/subscribe/subkey/ch2,ch1,ch3/asdf/qwer?zxcv=asdf&channel-group=g6,g4,g5"))
}

func TestUrlPathsMixedChannelsGroupsEqual(t *testing.T) {
	assert.True(t, matcher.MatchUrlStrings(
		"/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf&channel-group=g5,g6,g4",
		"/subscribe/subkey/ch2,ch1,ch3/asdf/qwer?zxcv=asdf&channel-group=g6,g4,g5"))
}

func TestUrlsMixedChannelsAndChannelGroupsNotEqual(t *testing.T) {
	assert.False(t, matcher.MatchUrlStrings(
		"http://foo.bar/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf&channel-group=g5,g6,g4",
		"http://foo.bar/subscribe/subkey/ch2,ch1,ch3/asdf/qwer?zxcv=asdf&channel-group=g6,g4,g3"))
}

func TestUrlPathsMixedChannelsGroupsNotEqual(t *testing.T) {
	assert.False(t, matcher.MatchUrlStrings(
		"/subscribe/subkey/ch1,ch3,ch2/asdf/qwer?zxcv=asdf&channel-group=g5,g6,g4",
		"/subscribe/subkey/ch2,ch1,ch3/asdf/qwer?zxcv=asdf&channel-group=g6,g3,g5"))
}
