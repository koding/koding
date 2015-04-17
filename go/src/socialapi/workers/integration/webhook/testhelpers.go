package webhook

import (
	"socialapi/models"
	"testing"

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
	name := "integration_test_" + models.RandomName()
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
	i.Title = "test_" + models.RandomName()
	i.Name = "test_" + models.RandomName()

	err := i.Create()
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
	i.GroupName = models.RandomName()
	i.IntegrationId = integration.Id
	err := i.Create()
	if err != nil {
		t.Fatal(err)
	}

	return i
}
