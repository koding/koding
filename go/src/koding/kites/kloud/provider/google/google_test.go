package google

import (
	"testing"

	"koding/kites/kloud/stack"
)

func TestValidators(t *testing.T) {
	tests := map[string]struct {
		Validator stack.Validator
		IsValid   bool
	}{
		"invalid cred JSON": {
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     `infra-treat-123456`,
				Region:      `us-central1`,
			},
			IsValid: false,
		},
		"valid cred": {
			Validator: &Cred{
				Credentials: `{
					"type": "service_account",
					"project_id": "infra-treat-103712",
					"private_key_id": "243523123324",
					"private_key": "-----BEGIN PRIVATE KEY-----\nPK\n-----END PRIVATE KEY-----\n"
					}`,
				Project: "infra-treat-103712",
				Region:  `us-central1`,
			},
			IsValid: true,
		},
		"unknown cred type": {
			Validator: &Cred{
				Credentials: `{
					"type": "unknown_account",
					"project_id": "infra-treat-103712",
					"private_key_id": "243523123324",
					"private_key": "-----BEGIN PRIVATE KEY-----\nPK\n-----END PRIVATE KEY-----\n"
					}`,
				Project: "infra-treat-103712",
				Region:  `us-central1`,
			},
			IsValid: false,
		},
		"invalid cred private_key": {
			Validator: &Cred{
				Credentials: `{
					"type": "unknown_account",
					"project_id": "infra-treat-103712",
					"private_key_id": "243523123324",
					"private_key": "-----BEGIN PUBLIC KEY-----\nPK\n-----END PUBLIC KEY-----\n"
					}`,
				Project: "infra-treat-103712",
				Region:  `us-central1`,
			},
			IsValid: false,
		},
		"empty cred project": {
			Validator: &Cred{
				Credentials: `{
					"type": "unknown_account",
					"project_id": "",
					"private_key_id": "243523123324",
					"private_key": "-----BEGIN PRIVATE KEY-----\nPK\n-----END PRIVATE KEY-----\n"
					}`,
				Project: "infra-treat-103712",
				Region:  `us-central1`,
			},
			IsValid: false,
		},
		"missing cred": {
			Validator: &Cred{
				Credentials: ``,
				Project:     `infra-treat-123456`,
				Region:      `us-central1`,
			},
			IsValid: false,
		},
		"missing project": {
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     ``,
				Region:      `us-central1`,
			},
			IsValid: false,
		},
		"missing region": {
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     `infra-treat-123456`,
				Region:      ``,
			},
			IsValid: false,
		},
		"invalid region": {
			Validator: &Cred{
				Credentials: `{"google":"secret"}`,
				Project:     `infra-treat-123456`,
				Region:      `invalid_region`,
			},
			IsValid: false,
		},
		"valid meta": {
			Validator: &Meta{
				Name:        `gce-development-instance`,
				Region:      `us-central1`,
				Zone:        `us-central1-a`,
				Image:       `ubuntu-1404-trusty-v20160919`,
				StorageSize: 10,
				MachineType: `f1-micro`,
			},
			IsValid: true,
		},
		"missing meta name": {
			Validator: &Meta{
				Name:        ``,
				Region:      `us-central1`,
				Zone:        `us-central1-a`,
				Image:       `ubuntu-1404-trusty-v20160919`,
				StorageSize: 10,
				MachineType: `f1-micro`,
			},
			IsValid: false,
		},
		"missing meta region": {
			Validator: &Meta{
				Name:        `gce-development-instance`,
				Region:      ``,
				Zone:        `us-central1-a`,
				Image:       `ubuntu-1404-trusty-v20160919`,
				StorageSize: 10,
				MachineType: `f1-micro`,
			},
			IsValid: false,
		},
		"missing meta zone": {
			Validator: &Meta{
				Name:        `gce-development-instance`,
				Region:      `us-central1`,
				Zone:        ``,
				Image:       `ubuntu-1404-trusty-v20160919`,
				StorageSize: 10,
				MachineType: `f1-micro`,
			},
			IsValid: false,
		},
		"missing meta image": {
			Validator: &Meta{
				Name:        `gce-development-instance`,
				Region:      `us-central1`,
				Zone:        `us-central1-a`,
				Image:       ``,
				StorageSize: 10,
				MachineType: `f1-micro`,
			},
			IsValid: false,
		},
		"meta with zero storage size": {
			Validator: &Meta{
				Name:        `gce-development-instance`,
				Region:      `us-central1`,
				Zone:        `us-central1-a`,
				Image:       `ubuntu-1404-trusty-v20160919`,
				StorageSize: 0,
				MachineType: `f1-micro`,
			},
			IsValid: true,
		},
		"missing meta machine type": {
			Validator: &Meta{
				Name:        `gce-development-instance`,
				Region:      `us-central1`,
				Zone:        `us-central1-a`,
				Image:       `ubuntu-1404-trusty-v20160919`,
				StorageSize: 10,
				MachineType: ``,
			},
			IsValid: false,
		},
		"empty koding network ID": {
			Validator: &Bootstrap{
				KodingNetworkID: ``,
			},
			IsValid: false,
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			err := test.Validator.Valid()

			if test.IsValid && err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if !test.IsValid && err == nil {
				t.Fatalf("want err != nil; got nil")
			}
		})
	}
}
