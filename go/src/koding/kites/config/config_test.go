package config

import (
	"fmt"
	"reflect"
	"testing"
)

func TestBucketGet(t *testing.T) {
	tests := []struct {
		Environment  string
		ProvEnv      string
		ProvBucket   *Bucket
		Exp          *Bucket
		ExpNoManaged *Bucket
	}{
		{
			// 0 //
			Environment:  "sandbox",
			ProvEnv:      "sandbox",
			ProvBucket:   &Bucket{Name: "bucket-sandbox", Region: "us-east-1"},
			Exp:          &Bucket{Name: "bucket-development", Region: "us-east-1"},
			ExpNoManaged: &Bucket{Name: "bucket-development", Region: "us-east-1"},
		},
		{
			// 1 //
			Environment:  "production",
			ProvEnv:      "managed",
			ProvBucket:   &Bucket{Name: "bucket-production", Region: "us-east-1"},
			Exp:          &Bucket{Name: "bucket-managed", Region: "us-east-1"},
			ExpNoManaged: &Bucket{Name: "bucket-production", Region: "us-east-1"},
		},
		{
			// 2 //
			Environment:  "production",
			ProvEnv:      "devmanaged",
			ProvBucket:   &Bucket{Name: "bucket-production", Region: "us-east-1"},
			Exp:          &Bucket{Name: "bucket-devmanaged", Region: "us-east-1"},
			ExpNoManaged: &Bucket{Name: "bucket-development", Region: "us-east-1"},
		},
		{
			// 3 //
			Environment:  "default",
			ProvEnv:      "sandbox",
			ProvBucket:   &Bucket{Name: "bucket-default", Region: "us-east-1"},
			Exp:          &Bucket{Name: "bucket-development", Region: "us-east-1"},
			ExpNoManaged: &Bucket{Name: "bucket-development", Region: "us-east-1"},
		},
		{
			// 4 //
			Environment:  "production",
			ProvEnv:      "production",
			ProvBucket:   &Bucket{Name: "bucket-production", Region: "us-east-1"},
			Exp:          &Bucket{Name: "bucket-production", Region: "us-east-1"},
			ExpNoManaged: &Bucket{Name: "bucket-production", Region: "us-east-1"},
		},
		{
			// 5 //
			Environment:  "development",
			ProvEnv:      "devmanaged",
			ProvBucket:   &Bucket{Name: "bucket-development", Region: "us-east-1"},
			Exp:          &Bucket{Name: "bucket-devmanaged", Region: "us-east-1"},
			ExpNoManaged: &Bucket{Name: "bucket-development", Region: "us-east-1"},
		},
		{
			// 6 //
			Environment:  "default",
			ProvEnv:      "devmanaged",
			ProvBucket:   &Bucket{Name: "bucket-default", Region: "us-east-1"},
			Exp:          &Bucket{Name: "bucket-devmanaged", Region: "us-east-1"},
			ExpNoManaged: &Bucket{Name: "bucket-development", Region: "us-east-1"},
		},
	}

	for i, test := range tests {
		t.Run(fmt.Sprintf("test_no_%d", i), func(t *testing.T) {
			// Temporarily replace buildin environment. This also means that you
			// should not run these test in parallel!
			var envcopy = environment
			environment = test.Environment
			defer func() {
				environment = envcopy
			}()

			if b := test.ProvBucket.Get(test.ProvEnv); !reflect.DeepEqual(b, test.Exp) {
				t.Fatalf("want bucket = %#v; got %#v", test.Exp, b)
			}

			if b := test.ProvBucket.Get(RmManaged(test.ProvEnv)); !reflect.DeepEqual(b, test.ExpNoManaged) {
				t.Fatalf("want bucket = %#v; got %#v", test.Exp, b)
			}
		})
	}
}

func TestEndpointGet(t *testing.T) {
	tests := []struct {
		Environment  string
		ProvEnv      string
		ProvEndpoint Endpoint
		Exp          Endpoint
		ExpNoManaged Endpoint
	}{
		{
			// 0 //
			Environment:  "sandbox",
			ProvEnv:      "sandbox",
			ProvEndpoint: "https://koding.com/sandbox/version.txt",
			Exp:          "https://koding.com/development/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 1 //
			Environment:  "production",
			ProvEnv:      "managed",
			ProvEndpoint: "https://koding.com/production/version.txt",
			Exp:          "https://koding.com/managed/version.txt",
			ExpNoManaged: "https://koding.com/production/version.txt",
		},
		{
			// 2 //
			Environment:  "production",
			ProvEnv:      "devmanaged",
			ProvEndpoint: "https://koding.com/production/version.txt",
			Exp:          "https://koding.com/devmanaged/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 3 //
			Environment:  "default",
			ProvEnv:      "sandbox",
			ProvEndpoint: "https://koding.com/default/version.txt",
			Exp:          "https://koding.com/development/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 4 //
			Environment:  "production",
			ProvEnv:      "production",
			ProvEndpoint: "https://koding.com/production/version.txt",
			Exp:          "https://koding.com/production/version.txt",
			ExpNoManaged: "https://koding.com/production/version.txt",
		},
		{
			// 5 //
			Environment:  "development",
			ProvEnv:      "devmanaged",
			ProvEndpoint: "https://koding.com/development/version.txt",
			Exp:          "https://koding.com/devmanaged/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 6 //
			Environment:  "default",
			ProvEnv:      "devmanaged",
			ProvEndpoint: "https://koding.com/default/version.txt",
			Exp:          "https://koding.com/devmanaged/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
	}

	for i, test := range tests {
		t.Run(fmt.Sprintf("test_no_%d", i), func(t *testing.T) {
			// Temporarily replace buildin environment. This also means that you
			// should not run these test in parallel!
			var envcopy = environment
			environment = test.Environment
			defer func() {
				environment = envcopy
			}()

			if e := test.ProvEndpoint.Get(test.ProvEnv); !reflect.DeepEqual(e, test.Exp) {
				t.Fatalf("want endpoint = %#v; got %#v", test.Exp, e)
			}

			if e := test.ProvEndpoint.Get(RmManaged(test.ProvEnv)); !reflect.DeepEqual(e, test.ExpNoManaged) {
				t.Fatalf("want endpoint = %#v; got %#v", test.Exp, e)
			}
		})
	}
}
