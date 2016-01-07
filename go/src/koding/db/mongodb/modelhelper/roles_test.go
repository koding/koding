package modelhelper

import (
	"koding/db/models"
	"testing"

	"gopkg.in/mgo.v2/bson"
)

func TestFetchAdminAccounts(t *testing.T) {
	initMongoConn()
	defer Close()

	acc1 := createTestAccount(t)
	defer RemoveAccount(acc1.Id)

	acc2 := createTestAccount(t)
	defer RemoveAccount(acc2.Id)

	group, err := createGroup()
	if err != nil {
		t.Error(err)
	}

	accounts, err := FetchAdminAccounts(group.Slug)
	if err != nil {
		t.Error(err)
	}

	if len(accounts) != 0 {
		t.Errorf("accounts count should be 0, got: %d", len(accounts))
	}

	if err := AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group.Id,
		SourceName: "JGroup",
		As:         "admin",
	}); err != nil {
		t.Error(err)
	}

	if err := AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc2.Id,
		TargetName: "JAccount",
		SourceId:   group.Id,
		SourceName: "JGroup",
		As:         "admin",
	}); err != nil {
		t.Error(err)
	}

	accounts, err = FetchAdminAccounts(group.Slug)
	if err != nil {
		t.Error(err)
	}

	if len(accounts) != 2 {
		t.Errorf("accounts count should be 2, got: %d", len(accounts))
	}
}
