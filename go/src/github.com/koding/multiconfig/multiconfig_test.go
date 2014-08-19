package multiconfig

import (
	"os"
	"testing"
)

type (
	Server struct {
		Name     string
		Port     int
		Enabled  bool
		Users    []string
		Postgres Postgres
	}

	// Postgres holds Postgresql database related configuration
	Postgres struct {
		Enabled           bool
		Port              int
		Hosts             []string
		DBName            string
		AvailabilityRatio float64
	}
)

var (
	testTOML = "testdata/config.toml"
	testJSON = "testdata/config.json"
)

func getDefaultServer() *Server {
	return &Server{
		Name:    "koding",
		Port:    6060,
		Enabled: true,
		Users:   []string{"ankara", "istanbul"},
		Postgres: Postgres{
			Enabled:           true,
			Port:              5432,
			Hosts:             []string{"192.168.2.1", "192.168.2.2", "192.168.2.3"},
			DBName:            "configdb",
			AvailabilityRatio: 8.23,
		},
	}
}

func TestNewWithPath(t *testing.T) {
	var _ Loader = NewWithPath(testTOML)
}

func TestLoad(t *testing.T) {
	m := NewWithPath(testTOML)

	s := new(Server)
	if err := m.Load(s); err != nil {
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

func TestJSON(t *testing.T) {
	m := NewWithPath(testJSON)

	s := &Server{}
	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	testStruct(t, s, getDefaultServer())
}

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

func testStruct(t *testing.T, s *Server, d *Server) {

	if s.Name != d.Name {
		t.Errorf("Name value is wrong: %s, want: %s", s.Name, d.Name)
	}

	if s.Port != d.Port {
		t.Errorf("Port value is wrong: %d, want: %d", s.Port, d.Port)
	}

	if s.Enabled != d.Enabled {
		t.Errorf("Enabled value is wrong: %t, want: %t", s.Enabled, d.Enabled)
	}

	if len(s.Users) != len(d.Users) {
		t.Errorf("Users value is wrong: %d, want: %d", len(s.Users), len(d.Users))
	} else {
		for i, user := range d.Users {
			if s.Users[i] != user {
				t.Errorf("User is wrong for index: %d, user: %s, want: %s", i, s.Users[i], user)
			}
		}
	}

	// Explicitly state that Enabled should be true, no need to check
	// `x == true` infact.
	if s.Postgres.Enabled != d.Postgres.Enabled {
		t.Errorf("Enabled is wrong %t, want: %t", s.Postgres.Enabled, d.Postgres.Enabled)
	}

	if s.Postgres.Port != d.Postgres.Port {
		t.Errorf("Port value is wrong: %d, want: %d", s.Postgres.Port, d.Postgres.Port)
	}

	if s.Postgres.DBName != d.Postgres.DBName {
		t.Errorf("DBName is wrong: %s, want: %s", s.Postgres.DBName, d.Postgres.DBName)
	}

	if s.Postgres.AvailabilityRatio != d.Postgres.AvailabilityRatio {
		t.Errorf("AvailabilityRatio is wrong: %f, want: %f", s.Postgres.AvailabilityRatio, d.Postgres.AvailabilityRatio)
	}

	if len(s.Postgres.Hosts) != len(d.Postgres.Hosts) {
		// do not continue testing if this fails, because others is depending on this test
		t.Fatalf("Hosts len is wrong: %v, want: %v", s.Postgres.Hosts, d.Postgres.Hosts)
	}

	for i, host := range d.Postgres.Hosts {
		if s.Postgres.Hosts[i] != host {
			t.Fatalf("Hosts number %d is wrong: %v, want: %v", i, s.Postgres.Hosts[i], host)
		}
	}
}
