package modelhelper_test

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"testing"

	"gopkg.in/mgo.v2/bson"
)

func TestGroupData(t *testing.T) {
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

	gd := &models.GroupData{}
	if err := modelhelper.GetGroupData(slug, gd); err != nil {
		t.Fatalf("GetGroupData(slug) = %v, want %v", err, nil)
	}

	res, err := gd.Payload.GetString("testData.key2.subkey2")
	if err != nil {
		t.Fatalf("data.Get(testData.key2.subkey2) = %v, want %v", err, nil)
	}

	if want := "val2"; res != want {
		t.Fatalf("res = %v, want %v", res, want)
	}

	// check if other keys are still existent
	testDataVal3, err := gd.Payload.GetString("testData.key3")
	if err != nil {
		t.Fatalf("data.Get(testData.key3) = %v, want %v", err, nil)
	}

	if testDataVal3 != "val3" {
		t.Fatalf("testDataVal3 = %v, want %v", testDataVal3, "val3")
	}

	updateVal := "updatedVal"
	if err := modelhelper.UpsertGroupData(slug, "testData.key2.subkey2", updateVal); err != nil {
		t.Fatalf("UpsertGroupData() = %v, want %v", err, nil)
	}

	gdp := &models.GroupData{}
	if err := modelhelper.GetGroupDataPath(slug, "testData.key2", gdp); err != nil {
		t.Fatalf("GetGroupDataPath() = %v, want %v", err, nil)
	}

	res, err = gdp.Payload.GetString("testData.key2.subkey2")
	if err != nil {
		t.Fatalf("data.Get(testData.key2.subkey2) = %v, want %v", err, nil)
	}

	if res != updateVal {
		t.Fatalf("res = %v, want %v", res, updateVal)
	}
}
