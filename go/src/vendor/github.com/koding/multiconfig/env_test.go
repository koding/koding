package multiconfig

import (
	"os"
	"strings"
	"testing"

	"github.com/fatih/structs"
)

func TestENV(t *testing.T) {
	m := EnvironmentLoader{}
	s := &Server{}
	structName := structs.Name(s)

	// set env variables
	setEnvVars(t, structName, "")

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestCamelCaseEnv(t *testing.T) {
	m := EnvironmentLoader{
		CamelCase: true,
	}
	s := &CamelCaseServer{}
	structName := structs.Name(s)

	// set env variables
	setEnvVars(t, structName, "")

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testCamelcaseStruct(t, s, getDefaultCamelCaseServer())
}

func TestENVWithPrefix(t *testing.T) {
	const prefix = "Prefix"

	m := EnvironmentLoader{Prefix: prefix}
	s := &Server{}
	structName := structs.New(s).Name()

	// set env variables
	setEnvVars(t, structName, prefix)

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

func TestENVFlattenStructPrefix(t *testing.T) {
	const prefix = "Prefix"

	m := EnvironmentLoader{Prefix: prefix}
	s := &TaggedServer{}
	structName := structs.New(s).Name()

	// set env variables
	setEnvVars(t, structName, prefix)

	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testPostgres(t, s.Postgres, getDefaultServer().Postgres)
}

func setEnvVars(t *testing.T, structName, prefix string) {
	if structName == "" {
		t.Fatal("struct name can not be empty")
	}

	var env map[string]string
	switch structName {
	case "Server":
		env = map[string]string{
			"NAME":                       "koding",
			"PORT":                       "6060",
			"ENABLED":                    "true",
			"USERS":                      "ankara,istanbul",
			"INTERVAL":                   "10s",
			"ID":                         "1234567890",
			"LABELS":                     "123,456",
			"POSTGRES_ENABLED":           "true",
			"POSTGRES_PORT":              "5432",
			"POSTGRES_HOSTS":             "192.168.2.1,192.168.2.2,192.168.2.3",
			"POSTGRES_DBNAME":            "configdb",
			"POSTGRES_AVAILABILITYRATIO": "8.23",
			"POSTGRES_FOO":               "8.23,9.12,11,90",
		}
	case "CamelCaseServer":
		env = map[string]string{
			"ACCESS_KEY":         "123456",
			"NORMAL":             "normal",
			"DB_NAME":            "configdb",
			"AVAILABILITY_RATIO": "8.23",
		}
	case "TaggedServer":
		env = map[string]string{
			"NAME":              "koding",
			"ENABLED":           "true",
			"PORT":              "5432",
			"HOSTS":             "192.168.2.1,192.168.2.2,192.168.2.3",
			"DBNAME":            "configdb",
			"AVAILABILITYRATIO": "8.23",
			"FOO":               "8.23,9.12,11,90",
		}
	}

	if prefix == "" {
		prefix = structName
	}

	prefix = strings.ToUpper(prefix)

	for key, val := range env {
		env := prefix + "_" + key
		if err := os.Setenv(env, val); err != nil {
			t.Fatal(err)
		}
	}
}

func TestENVgetPrefix(t *testing.T) {
	e := &EnvironmentLoader{}
	s := &Server{}

	st := structs.New(s)

	prefix := st.Name()

	if p := e.getPrefix(st); p != prefix {
		t.Errorf("Prefix is wrong: %s, want: %s", p, prefix)
	}

	prefix = "Test"
	e = &EnvironmentLoader{Prefix: prefix}
	if p := e.getPrefix(st); p != prefix {
		t.Errorf("Prefix is wrong: %s, want: %s", p, prefix)
	}
}
