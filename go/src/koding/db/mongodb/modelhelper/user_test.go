package modelhelper

import (
	"fmt"
	"koding/db/models"
	"os"
	"testing"
	"time"

	"log"

	"gopkg.in/mgo.v2/bson"
)

func initMongoConn() {
	// i didnt write this
	mongoURL := ""

	if url := os.Getenv("WERCKER_MONGODB_URL"); url != "" {
		mongoURL = url
	} else {
		mongoURL = os.Getenv("MONGODB_URL")
	}

	if mongoURL == "" {
		log.Fatalf("either WERCKER_MONGODB_URL or MONGODB_URL should be set")
	}

	Initialize(mongoURL)
}

func TestBlockUser(t *testing.T) {
	initMongoConn()
	defer Close()

	username, blockedReason := "testuser", "testing"

	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(), Status: UserStatusBlocked,
	}

	defer func() {
		RemoveUser(username)
	}()

	err := CreateUser(user)
	if err != nil {
		t.Error(err)
	}

	err = BlockUser(username, blockedReason, 1*time.Hour)
	if err != nil {
		t.Error(err)
	}

	user, err = GetUser(username)
	if err != nil {
		t.Error(err)
	}

	if user.Status != UserStatusBlocked {
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
	initMongoConn()
	defer Close()

	username := "testuser"
	user := &models.User{
		Name: username, ObjectId: bson.NewObjectId(),
	}

	err := CreateUser(user)
	if err != nil {
		t.Error(err)
	}

	err = RemoveUser(username)
	if err != nil {
		t.Error(err)
	}

	user, err = GetUser(username)
	if err == nil {
		t.Errorf("User should've been deleted, but wasn't")
	}
}

func TestGetAnyUserTokenFromGroup(t *testing.T) {
	initMongoConn()
	defer Close()

	id := bson.NewObjectId()
	username := id.Hex()
	user := &models.User{
		ObjectId: id,
		Name:     username,
		Email:    username + "@" + username + ".com",
	}

	err := CreateUser(user)
	if err != nil {
		t.Error(err)
	}

	groupName := bson.NewObjectId().Hex()

	key := fmt.Sprintf("foreignAuth.slack.%s.token", groupName)
	token := "token-123qwe"
	selector := bson.M{"username": username}
	update := bson.M{key: token}

	if err := UpdateUser(selector, update); err != nil {
		t.Error("Error while updating user")
	}

	id2 := bson.NewObjectId()
	username2 := id2.Hex()
	user2 := &models.User{
		ObjectId: id2,
		Name:     username2,
		Email:    username2 + "@" + username2 + ".com",
	}

	err = CreateUser(user2)
	if err != nil {
		t.Error(err)
	}

	groupName2 := bson.NewObjectId().Hex()
	key2 := fmt.Sprintf("foreignAuth.slack.%s.token", groupName2)
	token2 := "token-123qwe11"
	selector2 := bson.M{"username": username2}
	update2 := bson.M{key2: token2}

	if err := UpdateUser(selector2, update2); err != nil {
		t.Error("Error while updating user")
	}

	users, err := GetAnySlackTokenWithGroup(groupName)
	if err != nil {
		t.Error("Error while getting user token")
	}

	if len(users) != 1 {
		t.Error("Length of user should be 1")
	}

	err = RemoveUser(username)
	if err != nil {
		t.Error(err)
	}
}
