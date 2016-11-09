package softlayer_test

import (
	"testing"

	"koding/kites/kloud/provider/softlayer"
)

func TestCredential_Valid(t *testing.T) {
	c := &softlayer.Credential{
		Username: "xxxxxx",
		ApiKey:   "xxxxxxxxxxxxx",
	}

	err := c.Valid()
	if err != nil {
		t.Errorf("Should not error when Credential has valid properties")
	}
}

func TestCredential_Invalid(t *testing.T) {
	c := &softlayer.Credential{}

	err := c.Valid()
	if err == nil {
		t.Errorf("Should error when Credential has an invalid property")
	}
}
