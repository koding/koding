package services

import "testing"

func TestServices(t *testing.T) {
	sf := NewServices()
	err := sf.Register("github", Github{})
	if err != nil {
		t.Errorf("expected nil, but got %s", err)
	}

	err = sf.Register("github", Github{})
	if err != ErrServiceRegistered {
		t.Errorf("expected %s, but got %v", ErrServiceRegistered, err)
	}

	_, err = sf.Get("pivotal")
	if err != ErrServiceNotFound {
		t.Errorf("expected %s, but got %v", ErrServiceNotFound, err)
	}

	_, err = sf.Get("pagerduty")
	if err != ErrServiceNotFound {
		t.Errorf("expected %s, but got %v", ErrServiceNotFound, err)
	}
}
