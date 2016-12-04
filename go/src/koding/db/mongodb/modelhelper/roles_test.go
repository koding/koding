package modelhelper_test

import (
	"testing"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	mgo "gopkg.in/mgo.v2"
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
		Roles []string
		Has   bool
	}{
		{
			Title: "Member account",
			Nick:  acc1.Profile.Nickname,
			Slug:  group.Slug,
			Roles: []string{"member"},
			Has:   true,
		},
		{
			Title: "Member account with multi role",
			Nick:  acc1.Profile.Nickname,
			Slug:  group.Slug,
			Roles: []string{"member", "admin"},
			Has:   true,
		},
		{
			Title: "Member account with default roles",
			Nick:  acc1.Profile.Nickname,
			Slug:  group.Slug,
			Roles: modelhelper.DefaultRoles,
			Has:   true,
		},
		{
			Title: "Non-member account",
			Nick:  acc2.Profile.Nickname,
			Slug:  group.Slug,
			Roles: []string{"member"},
			Has:   false,
		},
		{
			Title: "Invalid role correct account",
			Nick:  acc1.Profile.Nickname,
			Slug:  group.Slug,
			Roles: []string{"admin"},
			Has:   false,
		},
		{
			Title: "Invalid role in-correct account",
			Nick:  acc2.Profile.Nickname,
			Slug:  group.Slug,
			Roles: []string{"admin"},
			Has:   false,
		},
	}

	for _, test := range tests {
		has, err := modelhelper.HasAnyRole(test.Nick, test.Slug, test.Roles...)
		if err != nil {
			t.Error(err)
		}
		if has != test.Has {
			t.Errorf("expected %q's \"has\" equal to %t, but it wasnt!", test.Title, test.Has)
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

func TestFetchAccountGroupNames(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc1 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc1.Id)

	groups, err := modelhelper.FetchAccountGroupNames(acc1.Profile.Nickname)
	if err != mgo.ErrNotFound {
		t.Fatalf("want err = %v; got %v", mgo.ErrNotFound, err)
	}

	if len(groups) != 0 {
		t.Fatalf("expected len(groups) to be 0, got groups: %+v", groups)
	}

	group1, err := createGroup()
	if err != nil {
		t.Fatal(err)
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

	groups, err = modelhelper.FetchAccountGroupNames(acc1.Profile.Nickname)
	if err != nil {
		t.Fatal(err)
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
		t.Fatal(err)
	}

	groups, err = modelhelper.FetchAccountGroupNames(acc1.Profile.Nickname)
	if err != nil {
		t.Fatal(err)
	}

	if len(groups) != 2 {
		t.Fatalf("expected len(groups) to be 2, got groups: %+v", groups)
	}
}

func TestFetchAccountGroups(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc1 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc1.Id)

	groups, err := modelhelper.FetchAccountGroups(acc1.Profile.Nickname)
	if err != mgo.ErrNotFound {
		t.Fatalf("want err = %v; got %v", mgo.ErrNotFound, err)
	}

	if len(groups) != 0 {
		t.Fatalf("expected len(groups) to be 0, got groups: %+v", groups)
	}

	group1, err := createGroup()
	if err != nil {
		t.Fatal(err)
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
		t.Fatal(err)
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
		t.Fatal(err)
	}

	groups, err = modelhelper.FetchAccountGroups(acc1.Profile.Nickname)
	if err != nil {
		t.Fatal(err)
	}

	if len(groups) != 2 {
		t.Fatalf("expected len(groups) to be 2, got groups: %+v", groups)
	}
}
