package webhook

import (
	"socialapi/models"
	"testing"

	"github.com/koding/bongo"

	"labix.org/v2/mgo/bson"
)

func createTestAccount(t *testing.T) *models.Account {
	account := models.NewAccount()
	account.Id = 0
	account.OldId = bson.NewObjectId().Hex()
	account.Nick = account.OldId
	err := account.Create()
	if err != nil {
		t.Fatal(err)
	}

	return account
}

func createTestGroupChannel(t *testing.T, a *models.Account) *models.Channel {

	testGroupChannel := models.NewChannel()
	name := "integration_test_" + models.RandomGroupName()
	testGroupChannel.CreatorId = a.Id
	testGroupChannel.Name = name
	testGroupChannel.TypeConstant = models.Channel_TYPE_GROUP
	err := testGroupChannel.Create()
	if err != nil {
		t.Fatal(err)
	}

	return testGroupChannel
}

func CreateTestIntegration(t *testing.T) *Integration {
	i := NewIntegration()
	i.Title = models.RandomGroupName()
	i.Name = i.Title

	err := i.Create()
	if err != nil {
		t.Fatal(err)
	}

	return i
}

func CreateIterableIntegration(t *testing.T) *Integration {

	i := NewIntegration()
	i.Title = "iterable"
	i.Name = "iterable"

	selector := map[string]interface{}{
		"name": i.Name,
	}

	// no need to make it idempotent
	err := i.One(bongo.NewQS(selector))
	if err == nil {
		return i
	}

	if err != bongo.RecordNotFound {
		t.Fatal(err)
	}

	err = i.Create()
	if err != nil {
		t.Fatal(err)
	}

	return i
}

func CreateTestChannelIntegration(t *testing.T) *ChannelIntegration {
	account := createTestAccount(t)

	channel := createTestGroupChannel(t, account)

	integration := CreateTestIntegration(t)

	i := NewChannelIntegration()
	i.CreatorId = account.Id
	i.ChannelId = channel.Id
	i.GroupName = models.RandomGroupName()
	i.IntegrationId = integration.Id
	err := i.Create()
	if err != nil {
		t.Fatal(err)
	}

	return i
}
