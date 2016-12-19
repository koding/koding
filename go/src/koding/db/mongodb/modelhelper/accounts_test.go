package modelhelper_test

import (
	"testing"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

func createTestAccount(t *testing.T) *models.Account {
	acc := &models.Account{
		Id: bson.NewObjectId(),
		Profile: models.AccountProfile{
			Nickname:  bson.NewObjectId().Hex(), // random username
			FirstName: bson.NewObjectId().Hex(),
			LastName:  bson.NewObjectId().Hex(),
		},
		Type:        "registered",
		SocialApiId: bson.NewObjectId().Hex(),
	}

	if err := modelhelper.CreateAccount(acc); err != nil {
		t.Error(err)
	}

	return acc
}

func TestGetAccountsByIds(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc1 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc1.Id)

	acc2 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc2.Id)

	acc3 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc3.Id)

	accounts, err := modelhelper.GetAccountsByIds([]bson.ObjectId{acc1.Id, acc2.Id, acc3.Id})
	if err != nil {
		t.Error(err)
	}

	if len(accounts) != 3 {
		t.Errorf("accounts count should be 3, got: %d", len(accounts))
	}
}

func TestGetAccountBySocialApiIds(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc1 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc1.Id)

	acc2 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc2.Id)

	acc3 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc3.Id)

	accounts, err := modelhelper.GetAccountBySocialApiIds(acc1.SocialApiId, acc2.SocialApiId, acc3.SocialApiId)
	if err != nil {
		t.Error(err)
	}

	if len(accounts) != 3 {
		t.Errorf("accounts count should be 3, got: %d", len(accounts))
	}
}
