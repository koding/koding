package modelhelper_test

import (
	"testing"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"

	"gopkg.in/mgo.v2/bson"
)

func TestSessionUpdateData(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()
	testUsername := "testusername"
	testGroupName := "testgroupname"
	ses, err := modelhelper.CreateSessionForAccount(testUsername, testGroupName)
	if err != nil {
		t.Error(err)
	}

	nonExistingKey := "nonExistingKey"
	val, err := ses.SessionData.GetString(nonExistingKey)
	if err != models.ErrDataKeyNotExists {
		t.Error("expected ErrDataKeyNotExists, got", err)
	}

	if val != "" {
		t.Error("expected empty string, got", val)
	}

	key := "chargeID"
	value := "chargeVal"

	customData := map[string]interface{}{
		key: value,
	}

	if err := modelhelper.UpdateSessionData(ses.ClientId, customData); err != nil {
		t.Error(err)
	}

	ses, err = modelhelper.GetSessionById(ses.Id.Hex())
	if err != nil {
		t.Error(err)
	}

	val, err = ses.SessionData.GetString(key)
	if err != nil {
		t.Error("expected nil, got", err)
	}

	if val != value {
		t.Error("expected", value, "got", val)
	}
}

func TestGetMostRecentSession(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()
	g, err := createGroup()
	if err != nil {
		t.Fatalf("createGroup()=%s", err)
	}

	newSession := func(long time.Duration) *models.Session {
		return &models.Session{
			Id:           bson.NewObjectId(),
			ClientId:     bson.NewObjectId().Hex(),
			Username:     "user",
			GroupName:    g.Slug,
			SessionBegan: time.Now().UTC().Add(long),
			LastAccess:   time.Now().UTC().Add(long),
		}
	}

	sessions := []*models.Session{
		newSession(0),
		newSession(10 * time.Minute),
		newSession(1 * time.Hour), // <- this is most recent
		newSession(15 * time.Second),
		newSession(58 * time.Minute),
		newSession(-1 * time.Hour),
	}

	for i, s := range sessions {
		if err := modelhelper.CreateSession(s); err != nil {
			t.Fatalf("%d: CreateSession()=%s", i, err)
		}
	}

	got, err := modelhelper.GetMostRecentSession("user")
	if err != nil {
		t.Fatalf("GetMostRecentSession()=%s", err)
	}

	if got.Id != sessions[2].Id {
		t.Fatalf("got %q, want %q", got.Id.Hex(), sessions[2].Id.Hex())
	}
}
