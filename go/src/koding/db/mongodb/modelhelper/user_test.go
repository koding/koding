package modelhelper_test

import (
	"fmt"
	"testing"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

func TestBlockUser(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	user, _, err := modeltesthelper.CreateUser(bson.NewObjectId().Hex())
	if err != nil {
		t.Error(err)
	}
	username, blockedReason := user.Name, "testing"

	defer modelhelper.RemoveUser(username)

	err = modelhelper.BlockUser(username, blockedReason, 1*time.Hour)
	if err != nil {
		t.Error(err)
	}

	user, err = modelhelper.GetUser(username)
	if err != nil {
		t.Error(err)
	}

	if user.Status != models.UserBlocked {
		t.Errorf("User status is not blocked")
	}

	if user.BlockedReason != blockedReason {
		t.Errorf("User blocked reason is not: %s", blockedReason)
	}

	if user.BlockedUntil.IsZero() {
		t.Errorf("User blocked until date is not set")
	}

	id, err := modelhelper.GetUserID(user.Name)
	if err != nil {
		t.Fatalf("GetUserID()=%s", err)
	}

	if id != user.ObjectId {
		t.Fatalf("got %q, want %q", id.Hex(), user.ObjectId.Hex())
	}
}

func TestRemoveUser(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	username := bson.NewObjectId().Hex()
	_, _, err := modeltesthelper.CreateUser(username)
	if err != nil {
		t.Error(err)
	}

	err = modelhelper.RemoveUser(username)
	if err != nil {
		t.Error(err)
	}

	_, err = modelhelper.GetUser(username)
	if err == nil {
		t.Errorf("User should've been deleted, but wasn't")
	}
}

func TestGetAnyUserTokenFromGroup(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	id := bson.NewObjectId()
	username := id.Hex()
	_, _, err := modeltesthelper.CreateUser(username)
	if err != nil {
		t.Error(err)
	}

	groupName := bson.NewObjectId().Hex()

	key := fmt.Sprintf("foreignAuth.slack.%s.token", groupName)
	token := "token-123qwe"
	selector := bson.M{"username": username}
	update := bson.M{key: token}

	if err := modelhelper.UpdateUser(selector, update); err != nil {
		t.Error("Error while updating user")
	}

	id2 := bson.NewObjectId()
	username2 := id2.Hex()
	_, _, err = modeltesthelper.CreateUser(username2)
	if err != nil {
		t.Error(err)
	}

	groupName2 := bson.NewObjectId().Hex()
	key2 := fmt.Sprintf("foreignAuth.slack.%s.token", groupName2)
	token2 := "token-123qwe11"
	selector2 := bson.M{"username": username2}
	update2 := bson.M{key2: token2}

	if err := modelhelper.UpdateUser(selector2, update2); err != nil {
		t.Error("Error while updating user")
	}

	users, err := modelhelper.GetAnySlackTokenWithGroup(groupName)
	if err != nil {
		t.Error("Error while getting user token")
	}

	if len(users) != 1 {
		t.Error("Length of user should be 1")
	}

	err = modelhelper.RemoveUser(username)
	if err != nil {
		t.Error(err)
	}
}

func TestUserLogin(t *testing.T) {
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

	ses, err := modelhelper.CreateSessionForAccount(acc1.Profile.Nickname, group.Slug)
	if err != nil {
		t.Error(err)
	}

	tests := []struct {
		Title    string
		Nick     string
		Slug     string
		ClientID string
		Err      error
	}{
		{
			Title:    "Member account",
			Nick:     acc1.Profile.Nickname,
			Slug:     group.Slug,
			ClientID: ses.ClientId,
			Err:      nil,
		},
		{
			Title:    "Re-testing with Member account",
			Nick:     acc1.Profile.Nickname,
			Slug:     group.Slug,
			ClientID: ses.ClientId,
			Err:      nil,
		},
		{
			Title:    "Non-member account",
			Nick:     acc2.Profile.Nickname,
			Slug:     group.Slug,
			ClientID: "",
			Err:      modelhelper.ErrNotParticipant,
		},
	}

	for _, test := range tests {
		t.Run(test.Title, func(t *testing.T) {
			ses, err := modelhelper.UserLogin(test.Nick, test.Slug)
			if err != test.Err {
				t.Errorf("expected Err equal to %q, but got %q!", test.Err, err)
			}

			if ses != nil && ses.ClientId != test.ClientID {
				t.Errorf("expected ClientID equal to %q, but got %q!", test.ClientID, ses.ClientId)
			}
		})
	}
}

func TestUserLoginSessionCreation(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc2 := createTestAccount(t)
	defer modelhelper.RemoveAccount(acc2.Id)

	group, err := createGroup()
	if err != nil {
		t.Error(err)
	}

	if err := modelhelper.AddRelationship(&models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   acc2.Id,
		TargetName: "JAccount",
		SourceId:   group.Id,
		SourceName: "JGroup",
		As:         "member",
	}); err != nil {
		t.Error(err)
	}

	ses, err := modelhelper.UserLogin(acc2.Profile.Nickname, group.Slug)
	if err != nil {
		t.Errorf("expected nil error, but got %q!", err)
	}

	if ses == nil || ses.ClientId == "" {
		t.Error("expected ses.ClientId to be set, but got empty!")
	}
}
