package modelhelper

import (
	"koding/db/models"
	"testing"

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
		Type: "registered",
	}

	if err := CreateAccount(acc); err != nil {
		t.Error(err)
	}

	return acc
}

func TestGetAccountsByIds(t *testing.T) {
	initMongoConn()
	defer Close()

	acc1 := createTestAccount(t)
	defer RemoveAccount(acc1.Id)

	acc2 := createTestAccount(t)
	defer RemoveAccount(acc2.Id)

	acc3 := createTestAccount(t)
	defer RemoveAccount(acc3.Id)

	accounts, err := GetAccountsByIds([]bson.ObjectId{acc1.Id, acc2.Id, acc3.Id})
	if err != nil {
		t.Error(err)
	}

	if len(accounts) != 3 {
		t.Errorf("accounts count should be 3, got: %d", len(accounts))
	}
}
