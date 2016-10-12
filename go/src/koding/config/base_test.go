package config

import (
	"reflect"
	"testing"
	"text/template"
)

func TestGetEnvironment(t *testing.T) {
	tests := []struct {
		Environment string
		ProvEnv     string
		Expected    string
	}{
		{
			// 0 //
			Environment: "development",
			ProvEnv:     "sandbox",
			Expected:    "development",
		},
		{
			// 1 //
			Environment: "production",
			ProvEnv:     "managed",
			Expected:    "managed",
		},
		{
			// 2 //
			Environment: "production",
			ProvEnv:     "devmanaged",
			Expected:    "devmanaged",
		},
		{
			// 3 //
			Environment: "default",
			ProvEnv:     "sandbox",
			Expected:    "development",
		},
		{
			// 4 //
			Environment: "production",
			ProvEnv:     "production",
			Expected:    "production",
		},
		{
			// 5 //
			Environment: "development",
			ProvEnv:     "devmanaged",
			Expected:    "devmanaged",
		},
	}

	for i, test := range tests {
		cfg := &Config{
			Environment: test.Environment,
		}
		if gotEnv := cfg.GetEnvironment(test.ProvEnv); gotEnv != test.Expected {
			t.Errorf("want env = %v; got %v (i:%d)", test.Expected, gotEnv, i)
		}
	}
}

func TestGetBucket(t *testing.T) {
	var testTmpls = map[string]*template.Template{
		`buckets.A`:    template.Must(template.New(`buckets.A`).Parse(`{"name":"bucket","region":"reg"}`)),
		`buckets.Tmpl`: template.Must(template.New(`buckets.Tmpl`).Parse(`{"name":"test-{{.Environment}}","region":"reg"}`)),
		`invalid.Tmpl`: template.Must(template.New(`invalid.Tmpl`).Parse(`{"name":"{{.Missing}}","region":"reg"}`)),
		`invalid.Json`: template.Must(template.New(`invalid.Json`).Parse(`{"name":bucket,"region":"reg"}`)),
	}

	tests := []struct {
		TypeName string
		ProvEnv  string
		Valid    bool
		Expected *Bucket
	}{
		{
			// 0 //
			TypeName: "buckets.A",
			ProvEnv:  "production",
			Valid:    true,
			Expected: &Bucket{
				Name:   "bucket",
				Region: "reg",
			},
		},
		{
			// 1 //
			TypeName: "buckets.Tmpl",
			ProvEnv:  "production",
			Valid:    true,
			Expected: &Bucket{
				Name:   "test-production",
				Region: "reg",
			},
		},
		{
			// 2 //
			TypeName: "buckets.Tmpl",
			ProvEnv:  "managed",
			Valid:    true,
			Expected: &Bucket{
				Name:   "test-managed",
				Region: "reg",
			},
		},
		{
			// 3 //
			TypeName: "buckets.Tmpl",
			ProvEnv:  "development",
			Valid:    true,
			Expected: &Bucket{
				Name:   "test-development",
				Region: "reg",
			},
		},
		{
			// 4 //
			TypeName: "buckets.Tmpl",
			ProvEnv:  "devmanaged",
			Valid:    true,
			Expected: &Bucket{
				Name:   "test-devmanaged",
				Region: "reg",
			},
		},
		{
			// 5 //
			TypeName: "invalid.Tmpl",
			ProvEnv:  "devmanaged",
			Valid:    false,
			Expected: nil,
		},
		{
			// 6 //
			TypeName: "invalid.Json",
			ProvEnv:  "devmanaged",
			Valid:    false,
			Expected: nil,
		},
	}

	for i, test := range tests {
		cfg := &Config{
			tmpls: testTmpls,
		}
		bucket, err := cfg.GetBucket(test.TypeName, test.ProvEnv)
		if (err == nil) != test.Valid {
			t.Errorf("want test valid %t; got err = %v (i:%d)", test.Valid, err, i)
			continue
		}

		if !reflect.DeepEqual(bucket, test.Expected) {
			t.Errorf("want bucket %v; got %v (i:%d)", test.Expected, bucket, i)
		}
	}
}

func TestGetEndpoint(t *testing.T) {
	var testTmpls = map[string]*template.Template{
		`endpoints.A`:    template.Must(template.New(`endpoints.A`).Parse(`"endpoint"`)),
		`endpoints.Tmpl`: template.Must(template.New(`endpoints.Tmpl`).Parse(`"test-{{.Environment}}"`)),
		`invalid.Tmpl`:   template.Must(template.New(`invalid.Tmpl`).Parse(`{"name":"{{.Missing}}","region":"reg"}`)),
		`invalid.Json`:   template.Must(template.New(`invalid.Json`).Parse(`{"name":bucket,"region":"reg"}`)),
	}

	tests := []struct {
		TypeName string
		ProvEnv  string
		Valid    bool
		Expected string
	}{
		{
			// 0 //
			TypeName: "endpoints.A",
			ProvEnv:  "production",
			Valid:    true,
			Expected: "endpoint",
		},
		{
			// 1 //
			TypeName: "endpoints.Tmpl",
			ProvEnv:  "production",
			Valid:    true,
			Expected: "test-production",
		},
		{
			// 2 //
			TypeName: "endpoints.Tmpl",
			ProvEnv:  "managed",
			Valid:    true,
			Expected: "test-managed",
		},
		{
			// 3 //
			TypeName: "endpoints.Tmpl",
			ProvEnv:  "development",
			Valid:    true,
			Expected: "test-development",
		},
		{
			// 4 //
			TypeName: "endpoints.Tmpl",
			ProvEnv:  "devmanaged",
			Valid:    true,
			Expected: "test-devmanaged",
		},
		{
			// 5 //
			TypeName: "invalid.Tmpl",
			ProvEnv:  "devmanaged",
			Valid:    false,
			Expected: "",
		},
		{
			// 6 //
			TypeName: "invalid.Json",
			ProvEnv:  "devmanaged",
			Valid:    false,
			Expected: "",
		},
	}

	for i, test := range tests {
		cfg := &Config{
			tmpls: testTmpls,
		}
		endpoint, err := cfg.GetEndpoint(test.TypeName, test.ProvEnv)
		if (err == nil) != test.Valid {
			t.Errorf("want test valid %t; got err = %v (i:%d)", test.Valid, err, i)
			continue
		}

		if endpoint != test.Expected {
			t.Errorf("want endpoint %v; got %v (i:%d)", test.Expected, endpoint, i)
		}
	}
}
