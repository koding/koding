package multiconfig

import "testing"

type Server struct {
	Name    string
	Port    int
	Enabled bool
	Users   []string
}

var (
	testTOML = "testdata/config.toml"
	testJSON = "testdata/config.json"
)

func TestNewWithPath(t *testing.T) {
	var _ Loader = NewWithPath(testTOML)
}

func TestLoad(t *testing.T) {
	m := NewWithPath(testTOML)

	s := new(Server)
	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	if s.Name != "Koding" {
		t.Errorf("Name value is wrong: %s, want: %s", s.Name, "Koding")
	}

	if s.Port != 6060 {
		t.Errorf("Port value is wrong: %s, want: %s", s.Port, 6060)
	}

	if !s.Enabled {
		t.Errorf("Enabled value is wrong: %s, want: %s", s.Port, true)
	}

	if len(s.Users) != 2 {
		t.Errorf("Users value is wrong: %s, want: %s", len(s.Users), 2)
	}
}
