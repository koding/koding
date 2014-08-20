package multiconfig

import (
	"os"
	"testing"
)

func TestENV(t *testing.T) {
	env := map[string]string{
		"SERVER_NAME":                       "koding",
		"SERVER_PORT":                       "6060",
		"SERVER_ENABLED":                    "true",
		"SERVER_USERS":                      "ankara,istanbul",
		"SERVER_POSTGRES_ENABLED":           "true",
		"SERVER_POSTGRES_PORT":              "5432",
		"SERVER_POSTGRES_HOSTS":             "192.168.2.1,192.168.2.2,192.168.2.3",
		"SERVER_POSTGRES_DBNAME":            "configdb",
		"SERVER_POSTGRES_AVAILABILITYRATIO": "8.23",
		"SERVER_POSTGRES_FOO":               "8.23,9.12,11,90",
	}

	for key, val := range env {
		if err := os.Setenv(key, val); err != nil {
			t.Fatal(err)
		}
	}

	m := New()

	s := &Server{}
	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}
