package modelhelper_test

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"

	"gopkg.in/mgo.v2/bson"
)

func TestGetCombinedAppStorageByAccountId(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc := createTestAccount(t)

	_, err := modelhelper.GetCombinedAppStorageByAccountId(acc.Id)
	if err == nil {
		t.Fatalf("error should be nil but got:", err)
	}

}

func TestCreateCombinedAppStorage(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc := createTestAccount(t)

	cs := &models.CombinedAppStorage{
		Id:        bson.NewObjectId(),
		AccountId: acc.Id,
	}

	if err := modelhelper.CreateCombinedAppStorage(cs); err != nil {
		t.Fatalf("error should be nil but got:", err)
	}

	if cs == nil {
		t.Fatal("CombinedAppStorage should not be nil")
	}

	if cs.AccountId != acc.Id {
		t.Fatalf("CombinedAppStorage Account id should equal: but got:", acc.Id, cs.AccountId)
	}
}

func TestGetAllCombinedAppStorageByAccountId(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	acc := createTestAccount(t)

	cs1 := &models.CombinedAppStorage{
		Id:        bson.NewObjectId(),
		AccountId: acc.Id,
	}

	if err := modelhelper.CreateCombinedAppStorage(cs1); err != nil {
		t.Fatalf("error should not be nil but got:", err)
	}

	if cs1 == nil {
		t.Fatal("CombinedAppStorage should not be nil")
	}

	if cs1.AccountId != acc.Id {
		t.Fatalf("CombinedAppStorage Account id should equal: but got:", acc.Id, cs1.AccountId)
	}

	css, err := modelhelper.GetAllCombinedAppStorageByAccountId(acc.Id)
	if err != nil {
		t.Fatalf("error should be nil but got:", err)
	}

	if len(css) != 1 {
		t.Fatalf("length of CombinedAppStorage should equal to 2, but got:", len(css))
	}
}
