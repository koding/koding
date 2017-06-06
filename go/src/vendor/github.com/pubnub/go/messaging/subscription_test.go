package messaging

import (
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"log"
	"testing"
)

func TestSubscriptionEntity(t *testing.T) {
	channels := *newSubscriptionEntity()
	infoLogger := log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile)

	successChannel, errorChannel := CreateSubscriptionChannels()

	channels.Add("qwer", successChannel, errorChannel, infoLogger)
	channels.Add("asdf", successChannel, errorChannel, infoLogger)
	channels.Add("zxcv", successChannel, errorChannel, infoLogger)

	assert.Equal(t, "", channels.ConnectedNamesString(), "should be equal")
	assert.Len(t, channels.NamesString(), 14, "should be 14")
	assert.Contains(t, channels.NamesString(), "asdf", "should contain asdf")
	assert.Contains(t, channels.NamesString(), "qwer", "should contain qwer")
	assert.Contains(t, channels.NamesString(), "zxcv", "should contain zxcv")
}

func TestSubscriptionPanicOnUndefinedResponseType(t *testing.T) {
	defer func() {
		if r := recover(); r != nil {
			assert.Equal(t, "Undefined response type: 0", r)
		}
	}()

	event := connectionEvent{}
	event.Bytes()
}

func TestSubscriptionRemoveNonExistingItem(t *testing.T) {
	items := testEntityWithOneItem()
	infoLogger := log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile)
	assert.False(t, items.Remove("blah", infoLogger))
}

func TestSubscriptionClear(t *testing.T) {
	assert := assert.New(t)

	items := testEntityWithOneItem()

	assert.Len(items.items, 1)
	items.Clear()

	assert.Zero(len(items.items))
}

func TestSubscriptionAbort(t *testing.T) {
	assert := assert.New(t)

	items := testEntityWithOneItem()

	assert.False(items.abortedMarker)
	assert.Len(items.items, 1)
	infoLogger := log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile)
	items.ApplyAbort(infoLogger)

	assert.False(items.abortedMarker)
	assert.Len(items.items, 1)

	items.Abort(infoLogger)

	assert.True(items.abortedMarker)
	assert.Len(items.items, 1)

	items.ApplyAbort(infoLogger)

	assert.True(items.abortedMarker)
	assert.Zero(len(items.items))
}

func TestSubscriptionResetConnected(t *testing.T) {
	assert := assert.New(t)

	items := testEntityWithOneItem()
	items.items["qwer"].Connected = true

	assert.Equal([]string{"qwer"}, items.ConnectedNames())
	infoLogger := log.New(ioutil.Discard, "", log.Ldate|log.Ltime|log.Lshortfile)
	items.ResetConnected(infoLogger)

	assert.Equal([]string{}, items.ConnectedNames())
}

func TestGetNonExistingItem(t *testing.T) {
	assert := assert.New(t)

	items := testEntityWithOneItem()

	item, ok := items.Get("asdf")

	assert.Nil(item)
	assert.False(ok)
}

func testEntityWithOneItem() *subscriptionEntity {
	items := newSubscriptionEntity()

	items.items["qwer"] = &subscriptionItem{}

	return items
}
