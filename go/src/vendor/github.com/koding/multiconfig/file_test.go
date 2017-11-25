package multiconfig

import (
	"os"
	"testing"
)

func TestYAML(t *testing.T) {
	m := NewWithPath(testYAML)

	s := &Server{}
	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestYAML_Reader(t *testing.T) {
	f, err := os.Open(testYAML)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()

	l := MultiLoader(&TagLoader{}, &YAMLLoader{Reader: f})
	s := &Server{}
	if err := l.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}
func TestToml(t *testing.T) {
	m := NewWithPath(testTOML)

	s := &Server{}
	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestToml_Reader(t *testing.T) {
	f, err := os.Open(testTOML)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()

	l := MultiLoader(&TagLoader{}, &TOMLLoader{Reader: f})
	s := &Server{}
	if err := l.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestJSON(t *testing.T) {
	m := NewWithPath(testJSON)

	s := &Server{}
	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestJSON_Reader(t *testing.T) {
	f, err := os.Open(testJSON)
	if err != nil {
		t.Fatal(err)
	}
	defer f.Close()

	l := MultiLoader(&TagLoader{}, &JSONLoader{Reader: f})
	s := &Server{}
	if err := l.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

// func TestJSON2(t *testing.T) {
// 	ExampleEnvironmentLoader()
// 	ExampleTOMLLoader()
// }
