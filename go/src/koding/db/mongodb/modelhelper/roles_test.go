package modelhelper_test

import (
	"testing"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

func TestHasRole(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc1 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc1.Id)

	acc2 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc2.Id)

	group, err := createGroup()
	if err != nil {
		t.Error(err)
	}

	if err := modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group.Id,
		SourceName: "JGroup",
		As:         "member",
	}); err != nil {
		t.Error(err)
	}

	tests := []struct {
		Title string
		Nick  string
		Slug  string
		Role  string
		Has   bool
	}{
		{
			Title: "Member account",
			Nick:  acc1.Profile.Nickname,
			Slug:  group.Slug,
			Role:  "member",
			Has:   true,
		},
		{
			Title: "Non-member account",
			Nick:  acc2.Profile.Nickname,
			Slug:  group.Slug,
			Role:  "member",
			Has:   false,
		},
		{
			Title: "Invalid role correct account",
			Nick:  acc1.Profile.Nickname,
			Slug:  group.Slug,
			Role:  "admin",
			Has:   false,
		},
		{
			Title: "Invalid role in-correct account",
			Nick:  acc1.Profile.Nickname,
			Slug:  group.Slug,
			Role:  "admin",
			Has:   false,
		},
	}

	for _, test := range tests {
		has, err := modelhelper.HasRole(test.Nick, test.Slug, test.Role)
		if err != nil {
			t.Error(err)
		}
		if has != test.Has {
			t.Error("expected %s's \"has\" equal to %t, but it wasnt!", test.Title, test.Has)
		}
	}
}

func TestFetchAdminAccounts(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc1 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc1.Id)

	acc2 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc2.Id)

	group, err := createGroup()
	if err != nil {
		t.Error(err)
	}

	accounts, err := modelhelper.FetchAdminAccounts(group.Slug)
	if err != nil {
		t.Error(err)
	}

	if len(accounts) != 0 {
		t.Errorf("accounts count should be 0, got: %d", len(accounts))
	}

	if err := modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group.Id,
		SourceName: "JGroup",
		As:         "admin",
	}); err != nil {
		t.Error(err)
	}

	if err := modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc2.Id,
		TargetName: "JAccount",
		SourceId:   group.Id,
		SourceName: "JGroup",
		As:         "admin",
	}); err != nil {
		t.Error(err)
	}

	accounts, err = modelhelper.FetchAdminAccounts(group.Slug)
	if err != nil {
		t.Error(err)
	}

	if len(accounts) != 2 {
		t.Errorf("accounts count should be 2, got: %d", len(accounts))
	}
}

func TestFetchAccountGroups(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc1 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc1.Id)

	groups, err := modelhelper.FetchAccountGroups(acc1.Profile.Nickname)
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

	if err := modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group1.Id,
		SourceName: "JGroup",
		As:         "member",
	}); err != nil {
		t.Error(err)
	}

	groups, err = modelhelper.FetchAccountGroups(acc1.Profile.Nickname)
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

	if err := modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group2.Id,
		SourceName: "JGroup",
		As:         "admin",
	}); err != nil {
		t.Error(err)
	}

	if err := modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc1.Id,
		TargetName: "JAccount",
		SourceId:   group2.Id,
		SourceName: "JGroup",
		As:         "member",
	}); err != nil {
		t.Fatalf(err.Error())
	}

	groups, err = modelhelper.FetchAccountGroups(acc1.Profile.Nickname)
	if err != nil {
		t.Fatalf(err.Error())
	}

	if len(groups) != 2 {
		t.Fatalf("expected len(groups) to be 2, got groups: %+v", groups)
	}

}
