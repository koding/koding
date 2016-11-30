package modelhelper_test

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"
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
	val, err := ses.Data.GetString(nonExistingKey)
	if err != models.ErrDataKeyNotExists {
		t.Error("expected ErrDataKeyNotExists, got", err)
	}

	if val != "" {
		t.Error("expected empty string, got", val)
	}

	key := "chargeID"
	value := "chargeVal"

	data := map[string]interface{}{
		key: value,
	}

	if err := modelhelper.UpdateSessionData(ses.ClientId, data); err != nil {
		t.Error(err)
	}

	ses, err = modelhelper.GetSessionById(ses.Id.Hex())
	if err != nil {
		t.Error(err)
	}

	val, err = ses.Data.GetString(key)
	if err != nil {
		t.Error("expected nil, got", err)
	}

	if val != value {
		t.Error("expected", value, "got", val)
	}
}
