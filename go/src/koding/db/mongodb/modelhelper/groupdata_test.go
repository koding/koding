package modelhelper_test

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"reflect"
	"testing"

	"gopkg.in/mgo.v2/bson"
)

func TestGroupDataUpsert(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	slug := bson.NewObjectId().Hex()

	testData := map[string]interface{}{
		"key1": "val1",
		"key2": map[string]interface{}{
			"subkey2": "val2",
		},
		"key3": "val3",
	}

	if err := modelhelper.UpsertGroupData(slug, "testData", testData); err != nil {
		t.Fatalf("UpsertGroupData() = %v, want %v", err, nil)
	}

	gd, err := modelhelper.GetGroupData(slug)
	if err != nil {
		t.Fatalf("GetGroupData(slug) = %v, want %v", err, nil)
	}

	res, err := gd.Data.GetString("testData.key2.subkey2")
	if err != nil {
		t.Fatalf("data.Get(testData.key2.subkey2) = %v, want %v", err, nil)
	}

	if want := "val2"; res != want {
		t.Fatalf("res = %v, want %v", res, want)
	}

	updateVal := "updatedVal"
	if err := modelhelper.UpsertGroupData(slug, "testData.key2.subkey2", updateVal); err != nil {
		t.Fatalf("UpsertGroupData() = %v, want %v", err, nil)
	}

	gd, err = modelhelper.GetGroupData(slug)
	if err != nil {
		t.Fatalf("GetGroupData(slug) = %v, want %v", err, nil)
	}

	res, err = gd.Data.GetString("testData.key2.subkey2")
	if err != nil {
		t.Fatalf("data.Get(testData.key2.subkey2) = %v, want %v", err, nil)
	}

	if res != updateVal {
		t.Fatalf("res = %v, want %v", res, updateVal)
	}

	// check if other keys are still existent
	_, err = gd.Data.GetString("testData.key3")
	if err != models.ErrDataKeyNotExists {
		t.Fatalf("data.Get(testData.key3) = %v, want %v", err, nil)
	}
}

func TestPreparePath(t *testing.T) {
	path := "key1.key2.key3"
	data := "val"
	res := bson.M{
		"key1": bson.M{
			"key2": bson.M{
				"key3": "val",
			},
		},
	}

	mpath := modelhelper.PreparePath(path, data)
	if !reflect.DeepEqual(res, mpath) {
		t.Fatalf("mpath: %v, want %v", mpath, res)
	}
}
