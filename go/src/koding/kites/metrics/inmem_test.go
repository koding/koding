package metrics

import "testing"

func TestInMemRead(t *testing.T) {
	m, err := NewWithStorage(newInMemStorage(), "test")
	if err != nil {
		t.Fatal(err.Error())
	}
	testStorageRead(t, m)
}

func TestInMemForEachN(t *testing.T) {
	m, err := NewWithStorage(newInMemStorage(), "test")
	if err != nil {
		t.Fatal(err.Error())
	}
	testStorageForEachN(t, m)
}
