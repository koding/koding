package multiconfig

import "testing"

func TestDefaultValues(t *testing.T) {
	m := NewWithPath(testTOML)

	s := new(Server)
	if err := m.Load(s); err != nil {
		t.Error(err)
	}

	if s.Port != getDefaultServer().Port {
		t.Errorf("Port value is wrong: %d, want: %d", s.Port, getDefaultServer().Port)
	}
}
