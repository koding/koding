package google

import (
	"testing"

	"koding/kites/kloud/stack"
)

func TestValidators(t *testing.T) {
	tests := []struct {
		Validator stack.Validator
		IsValid   bool
	}{
		{
			// 0 //
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     `infra-treat-123456`,
				Region:      `us-central1`,
			},
			IsValid: true,
		},
		{
			// 1 //
			Validator: &Cred{
				Credentials: ``,
				Project:     `infra-treat-123456`,
				Region:      `us-central1`,
			},
			IsValid: false,
		},
		{
			// 2 //
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     ``,
				Region:      `us-central1`,
			},
			IsValid: false,
		},
		{
			// 3 //
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     `infra-treat-123456`,
				Region:      ``,
			},
			IsValid: false,
		},
		{
			// 4 //
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     `infra-treat-123456`,
				Region:      `invalid_region`,
			},
			IsValid: false,
		},
		{
			// 5 //
			Validator: &Bootstrap{
				Address:  "127.0.0.1",
				SelfLink: `http://google.koding.com/instance`,
			},
			IsValid: true,
		},
		{
			// 6 //
			Validator: &Bootstrap{
				Address:  "",
				SelfLink: `http://google.koding.com/instance`,
			},
			IsValid: false,
		},
		{
			// 7 //
			Validator: &Bootstrap{
				Address:  "127.0.0.1",
				SelfLink: ``,
			},
			IsValid: false,
		},
	}

	for i, test := range tests {
		err := test.Validator.Valid()

		if test.IsValid && err != nil {
			t.Errorf("want err = nil; got %v (i:%d)", err, i)
		}

		if !test.IsValid && err == nil {
			t.Errorf("want err != nil; got nil (i:%d)", i)
		}
	}
}
