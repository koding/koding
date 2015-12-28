package modelhelper

import (
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
