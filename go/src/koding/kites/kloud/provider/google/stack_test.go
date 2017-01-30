package google

import (
	"reflect"
	"testing"
)

func TestAddPublicKey(t *testing.T) {
	tests := map[string]struct {
		Name      string
		Metadata  map[string]interface{}
		User      string
		PublicKey string
		Expected  map[string]interface{}
	}{
		"no user SSH keys": {
			Metadata: map[string]interface{}{
				"unrelated": 5,
			},
			User:      "user",
			PublicKey: "pk",
			Expected: map[string]interface{}{
				"ssh-keys":  "user:pk",
				"unrelated": 5,
			},
		},
		"user SSH keys new format": {
			Metadata: map[string]interface{}{
				"ssh-keys": "user_custom:pk_custom",
			},
			User:      "user",
			PublicKey: "pk",
			Expected: map[string]interface{}{
				"ssh-keys": "user:pk\\nuser_custom:pk_custom",
			},
		},
		"user SSH keys deprecated format": {
			Metadata: map[string]interface{}{
				"sshKeys": "user_custom:pk_custom",
			},
			User:      "user",
			PublicKey: "pk",
			Expected: map[string]interface{}{
				"sshKeys": "user:pk\\nuser_custom:pk_custom",
			},
		},
		"user SSH keys both formats": {
			Metadata: map[string]interface{}{
				"ssh-keys": "user_custom_new:pk_custom_new",
				"sshKeys":  "user_custom_old:pk_custom_old",
			},
			User:      "user",
			PublicKey: "pk",
			Expected: map[string]interface{}{
				"ssh-keys": "user:pk\\nuser_custom_new:pk_custom_new",
				"sshKeys":  "user_custom_old:pk_custom_old",
			},
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			metadata := addPublicKey(test.Metadata, test.User, test.PublicKey)
			if !reflect.DeepEqual(metadata, test.Expected) {
				t.Fatalf("want metadata = %#v; got %#v", test.Expected, metadata)
			}
		})
	}
}

func TestFlatten(t *testing.T) {
	tests := map[string]struct {
		Data     []map[string]interface{}
		Expected map[string]interface{}
	}{
		"nil data": {
			Data:     nil,
			Expected: map[string]interface{}{},
		},
		"nil map": {
			Data: []map[string]interface{}{
				nil,
				{
					"user-data": "data",
				},
			},
			Expected: map[string]interface{}{
				"user-data": "data",
			},
		},
		"single map": {
			Data: []map[string]interface{}{
				{
					"user-data": "data",
				},
			},
			Expected: map[string]interface{}{
				"user-data": "data",
			},
		},
		"redefined map fields": {
			Data: []map[string]interface{}{
				{
					"user-data": "first",
				},
				{
					"user-data": "second",
				},
			},
			Expected: map[string]interface{}{
				"user-data": "first\nsecond",
			},
		},
		"different map fields": {
			Data: []map[string]interface{}{
				{
					"aaaa": "first",
				},
				{
					"bbbb": "second",
				},
			},
			Expected: map[string]interface{}{
				"aaaa": "first",
				"bbbb": "second",
			},
		},
		"map fields mix": {
			Data: []map[string]interface{}{
				{
					"aaaa": "first",
				},
				{
					"bbbb": "second",
				},
				{
					"aaaa": "A",
					"bbbb": "B",
					"cccc": "C",
				},
			},
			Expected: map[string]interface{}{
				"aaaa": "first\nA",
				"bbbb": "second\nB",
				"cccc": "C",
			},
		},
	}

	for name, test := range tests {
		// capture range variable here
		test := test
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			flattened := flatten(test.Data)
			if !reflect.DeepEqual(flattened, test.Expected) {
				t.Fatalf("want flattened = %#v; got %#v", test.Expected, flattened)
			}
		})
	}
}
