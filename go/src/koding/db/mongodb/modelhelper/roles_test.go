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

func TestFetchAccountGroups(t *testing.T) {
	initMongoConn()
	defer Close()

	acc1 := createTestAccount(t)
	defer RemoveAccount(acc1.Id)

	groups, err := FetchAccountGroups(acc1.Profile.Nickname)
	if err != nil {
		t.Fatalf(err.Error())
	}

	if len(groups) != 0 {
		t.Fatalf("expected len(groups) to be 0, got groups: %+v", groups)
	}

	group1, err := createGroup()
	if err != nil {
		t.Fatalf(err.Error())
	}

	if err := AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group1.Id,
		SourceName: "JGroup",
		As:         "member",
	}); err != nil {
		t.Error(err)
	}

	groups, err = FetchAccountGroups(acc1.Profile.Nickname)
	if err != nil {
		t.Fatalf(err.Error())
	}

	if len(groups) != 1 {
		t.Fatalf("expected len(groups) to be 1, got groups: %+v", groups)
	}

	// test having 2 relationsips in one group
	group2, err := createGroup()
	if err != nil {
		t.Error(err)
	}

	if err := AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group2.Id,
		SourceName: "JGroup",
		As:         "admin",
	}); err != nil {
		t.Error(err)
	}

	if err := AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group2.Id,
		SourceName: "JGroup",
		As:         "member",
	}); err != nil {
		t.Fatalf(err.Error())
	}

	groups, err = FetchAccountGroups(acc1.Profile.Nickname)
	if err != nil {
		t.Fatalf(err.Error())
	}

	if len(groups) != 2 {
		t.Fatalf("expected len(groups) to be 2, got groups: %+v", groups)
	}

}
