package models

import "testing"

var (
	existingKey, existingVal = "key1", "val1"
	nonExistingKey           = "key-non-existing"
	testData                 = Data{
		existingKey: existingVal,
		"key2": Data{
			"subkey2": "val2",
		},
		"key3": "val3",
		"key4": 4,
	}
)

func TestDataFindPath(t *testing.T) {
	// finding existing key
	d, ok := findPath(testData, existingKey)
	if !ok {
		t.Fatalf("existingKey: %v should be found", existingKey)
	}
	if s, ok := d.(string); !ok {
		t.Fatalf("%v 's value should be set as string, got %#v", existingKey, d)
	} else if s != existingVal {
		t.Fatalf("%v 's value should be %v, got: %v", existingKey, existingVal, s)
	}

	// finding non existing key
	d, ok = findPath(testData, nonExistingKey)
	if ok {
		t.Fatalf("%v should not be found", nonExistingKey)
	}
	if d != nil {
		t.Fatalf("%v's value should be nil, got: %v", nonExistingKey, d)
	}

	// finding multi level existing
	d, ok = findPath(testData, []string{"key2", "subkey2"}...)
	if !ok {
		t.Fatalf(" %v should be found", "key2.subkey2")
	}
	if s, ok := d.(string); !ok {
		t.Fatalf("%v 's value should be set as string, got %#v", "key2.subkey2", d)
	} else if s != "val2" {
		t.Fatalf("%v 's value should be %v, got: %v", "key2.subkey2", "val2", s)
	}

	// finding multi level non existing
	d, ok = findPath(testData, []string{"key2", "subKey3"}...)
	if ok {
		t.Fatalf(" %v should not be found", "key2.subKey3")
	}
	if d != nil {
		t.Fatalf("%v's value should be nil, got: %v", "key2.subKey3", d)
	}
}

func TestDataGet(t *testing.T) {
	// finding existing key
	data, err := testData.Get(existingKey)
	if err != nil {
		t.Fatalf("testData.Get() = error %v: got: %v", err, nil)
	}

	if s, ok := data.(string); !ok {
		t.Fatalf("%v 's value should be set as string, got %#v", existingKey, data)
	} else if s != existingVal {
		t.Fatalf("%v 's value should be %v, got: %v", existingKey, existingVal, s)
	}

	// finding non existing key
	data, err = testData.Get(nonExistingKey)
	if err != ErrDataKeyNotExists {
		t.Fatalf("testData.Get() = error %v: got: %v", err, ErrDataKeyNotExists)
	}
	if data != "" {
		t.Fatalf("%v's value should be empty string, got: %v", nonExistingKey, data)
	}

	// finding multi level existing
	data, err = testData.Get("key2.subkey2")
	if err != nil {
		t.Fatalf("testData.Get(key2.subkey2) = error %v: got: %v", err, nil)
	}

	if s, ok := data.(string); !ok {
		t.Fatalf("%v 's value should be set as string, got %#v", "key2.subkey2", data)
	} else if s != "val2" {
		t.Fatalf("%v 's value should be %v, got: %v", "key2.subkey2", "val2", s)
	}

	// finding multi level non existing
	_, err = testData.Get("key2.subkey3")
	if err != ErrDataKeyNotExists {
		t.Fatalf("testData.Get(key2.subkey2) = error %v: got: %v", err, ErrDataKeyNotExists)
	}
}

func TestDataGetString(t *testing.T) {
	data, err := testData.GetString(existingKey)
	if err != nil {
		t.Fatalf("testData.GetString() = error %v: got: %v", err, nil)
	}

	if data != existingVal {
		t.Fatalf("%v 's value should be %v, got: %v", existingKey, existingVal, data)
	}

	_, err = testData.GetString("key4")
	if err != ErrDataInvalidType {
		t.Fatalf("testData.GetString() = error %v: got: %v", err, ErrDataInvalidType)
	}
}
