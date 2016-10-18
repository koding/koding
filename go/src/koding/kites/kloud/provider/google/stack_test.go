package google

import (
	"reflect"
	"testing"
)

func TestAddPublicKey(t *testing.T) {
	tests := []struct {
		Name      string
		Metadata  map[string]interface{}
		User      string
		PublicKey string
		Expected  map[string]interface{}
	}{
		{
			Name: `no user SSH keys`,
			Metadata: map[string]interface{}{
				`unrelated`: 5,
			},
			User:      `user`,
			PublicKey: `pk`,
			Expected: map[string]interface{}{
				`ssh-keys`:  `user:pk`,
				`unrelated`: 5,
			},
		},
		{
			Name: `user SSH keys new format`,
			Metadata: map[string]interface{}{
				`ssh-keys`: `user_custom:pk_custom`,
			},
			User:      `user`,
			PublicKey: `pk`,
			Expected: map[string]interface{}{
				`ssh-keys`: `user:pk\nuser_custom:pk_custom`,
			},
		},
		{
			Name: `user SSH keys deprecated format`,
			Metadata: map[string]interface{}{
				`sshKeys`: `user_custom:pk_custom`,
			},
			User:      `user`,
			PublicKey: `pk`,
			Expected: map[string]interface{}{
				`sshKeys`: `user:pk\nuser_custom:pk_custom`,
			},
		},
		{
			Name: `user SSH keys both formats`,
			Metadata: map[string]interface{}{
				`ssh-keys`: `user_custom_new:pk_custom_new`,
				`sshKeys`:  `user_custom_old:pk_custom_old`,
			},
			User:      `user`,
			PublicKey: `pk`,
			Expected: map[string]interface{}{
				`ssh-keys`: `user:pk\nuser_custom_new:pk_custom_new`,
				`sshKeys`:  `user_custom_old:pk_custom_old`,
			},
		},
	}

	for _, test := range tests {
		t.Run(test.Name, func(t *testing.T) {
			metadata := addPublicKey(test.Metadata, test.User, test.PublicKey)
			if !reflect.DeepEqual(metadata, test.Expected) {
				t.Fatalf(`want metadata = %#v; got %#v`, test.Expected, metadata)
			}
		})
	}
}
