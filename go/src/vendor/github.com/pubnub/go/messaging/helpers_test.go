package messaging

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestAddPnpresToString(t *testing.T) {
	assert := assert.New(t)

	assert.Equal("", addPnpresToString(""))
	assert.Equal("qwer-pnpres", addPnpresToString("qwer"))
	assert.Equal("qwer-pnpres,asdf-pnpres,zxcv-pnpres",
		addPnpresToString("qwer,asdf,zxcv"))
}

func TestSplitItems(t *testing.T) {
	assert := assert.New(t)

	assert.Equal([]string{}, splitItems(""))
	assert.Equal([]string{"ch1"}, splitItems("ch1"))
	assert.Equal([]string{"ch1", "ch2"}, splitItems("ch1,ch2"))
}

func TestRemovePnpres(t *testing.T) {
	assert := assert.New(t)

	assert.Equal("ch1", removePnpres("ch1"))
	assert.Equal("ch1", removePnpres("ch1-pnpres"))
}

func TestOnlyPresence(t *testing.T) {
	assert := assert.New(t)

	assert.True(hasNonPresenceChannels("qwer"))
	assert.True(hasNonPresenceChannels("qwer,asdf"))
	assert.True(hasNonPresenceChannels("qwer,asdf-pnpres"))
	assert.False(hasNonPresenceChannels("qwer-pnpres"))
	assert.False(hasNonPresenceChannels("qwer-pnpres,asdf-pnpres"))
}
