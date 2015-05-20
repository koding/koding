package services

import (
	"testing"
)

func TestServiceInput(t *testing.T) {
	si := ServiceInput{}
	val := si.Key("hey")
	if val != nil {
		t.Errorf("unexpected val: '%v'", val)
	}

	si = ServiceInput{}
	si["electric"] = "mayhem"
	val = si.Key("electric")
	v, ok := val.(string)
	if !ok {
		t.Errorf("type cast error")
	}

	if v != "mayhem" {
		t.Errorf("unexpected val: '%s'", v)
	}

	si = ServiceInput{}
	si.SetKey("electric", "mayhem")
	val, ok = si["electric"]

	if !ok {
		t.Errorf("type cast error")
	}

	v, ok = val.(string)
	if v != "mayhem" {
		t.Errorf("unexpected val: '%s'", v)
	}

}
