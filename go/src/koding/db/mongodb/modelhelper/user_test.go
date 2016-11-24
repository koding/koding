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

	username, blockedReason := "testuser", "testing"

	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(), Status: models.UserBlocked,
	}

	defer func() {
		modelhelper.RemoveUser(username)
	}()

	err := modelhelper.CreateUser(user)
	if err != nil {
		t.Error(err)
	}

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
}

func TestRemoveUser(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	username := "testuser"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
	}

	err := modelhelper.CreateUser(user)
	if err != nil {
		t.Error(err)
	}

	err = modelhelper.RemoveUser(username)
	if err != nil {
		t.Error(err)
	}

	user, err = modelhelper.GetUser(username)
	if err == nil {
		t.Errorf("User should've been deleted, but wasn't")
	}
}

func TestGetAnyUserTokenFromGroup(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	id := bson.NewObjectId()
	username := id.Hex()
	user := &models.User{
		ObjectId: id,
		Name:     username,
		Email:    username + "@" + username + ".com",
	}

	err := modelhelper.CreateUser(user)
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
	user2 := &models.User{
		ObjectId: id2,
		Name:     username2,
		Email:    username2 + "@" + username2 + ".com",
	}

	err = modelhelper.CreateUser(user2)
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
