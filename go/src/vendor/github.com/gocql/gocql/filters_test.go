package gocql

import "testing"

func TestFilter_WhiteList(t *testing.T) {
	f := WhiteListHostFilter("addr1", "addr2")
	tests := [...]struct {
		addr   string
		accept bool
	}{
		{"addr1", true},
		{"addr2", true},
		{"addr3", false},
	}

	for i, test := range tests {
		if f.Accept(&HostInfo{peer: test.addr}) {
			if !test.accept {
				t.Errorf("%d: should not have been accepted but was", i)
			}
		} else if test.accept {
			t.Errorf("%d: should have been accepted but wasn't", i)
		}
	}
}

func TestFilter_AllowAll(t *testing.T) {
	f := AcceptAllFilter()
	tests := [...]struct {
		addr   string
		accept bool
	}{
		{"addr1", true},
		{"addr2", true},
		{"addr3", true},
	}

	for i, test := range tests {
		if f.Accept(&HostInfo{peer: test.addr}) {
			if !test.accept {
				t.Errorf("%d: should not have been accepted but was", i)
			}
		} else if test.accept {
			t.Errorf("%d: should have been accepted but wasn't", i)
		}
	}
}

func TestFilter_DenyAll(t *testing.T) {
	f := DenyAllFilter()
	tests := [...]struct {
		addr   string
		accept bool
	}{
		{"addr1", false},
		{"addr2", false},
		{"addr3", false},
	}

	for i, test := range tests {
		if f.Accept(&HostInfo{peer: test.addr}) {
			if !test.accept {
				t.Errorf("%d: should not have been accepted but was", i)
			}
		} else if test.accept {
			t.Errorf("%d: should have been accepted but wasn't", i)
		}
	}
}

func TestFilter_DataCentre(t *testing.T) {
	f := DataCentreHostFilter("dc1")
	tests := [...]struct {
		dc     string
		accept bool
	}{
		{"dc1", true},
		{"dc2", false},
	}

	for i, test := range tests {
		if f.Accept(&HostInfo{dataCenter: test.dc}) {
			if !test.accept {
				t.Errorf("%d: should not have been accepted but was", i)
			}
		} else if test.accept {
			t.Errorf("%d: should have been accepted but wasn't", i)
		}
	}
}
