package configstore_test

import (
	"reflect"
	"testing"

	"koding/kites/config/configstore"
)

func TestSetFlatKeyValue(t *testing.T) {
	cases := map[string]struct {
		key   string
		value string
		want  map[string]interface{}
		ok    bool
	}{
		"set simple key": {
			"debug",
			"true",
			map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"public":  "https://koding.com",
						"private": "http://127.0.0.1",
					},
				},
				"kdLatest": "http://127.0.0.1/latest-version.txt",
				"debug":    "true",
			},
			true,
		},
		"set compound key": {
			"endpoints.koding.public",
			"http://rjeczalik.koding.team",
			map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"public":  "http://rjeczalik.koding.team",
						"private": "http://127.0.0.1",
					},
				},
				"kdLatest": "http://127.0.0.1/latest-version.txt",
				"debug":    "false",
			},
			true,
		},
		"overwrite existing key": {
			"kdLatest",
			"http://localhost/latest-version.txt",
			map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"public":  "https://koding.com",
						"private": "http://127.0.0.1",
					},
				},
				"kdLatest": "http://localhost/latest-version.txt",
				"debug":    "false",
			},
			true,
		},
		"add new simple key": {
			"klientLatest",
			"http://127.0.0.1/latest-version.txt",
			map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"public":  "https://koding.com",
						"private": "http://127.0.0.1",
					},
				},
				"kdLatest":     "http://127.0.0.1/latest-version.txt",
				"klientLatest": "http://127.0.0.1/latest-version.txt",
				"debug":        "false",
			},
			true,
		},
		"add new compound key": {
			"endpoints.tunnel.public",
			"http://t.koding.com",
			map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"public":  "https://koding.com",
						"private": "http://127.0.0.1",
					},
					"tunnel": map[string]interface{}{
						"public": "http://t.koding.com",
					},
				},
				"kdLatest": "http://127.0.0.1/latest-version.txt",
				"debug":    "false",
			},
			true,
		},
		"invalid simple key overwrite": {
			"debug.invalid.key",
			"false",
			nil,
			false,
		},

		"unset simple key": {
			"debug",
			"",
			map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"public":  "https://koding.com",
						"private": "http://127.0.0.1",
					},
				},
				"kdLatest": "http://127.0.0.1/latest-version.txt",
			},
			true,
		},
		"unset compound key": {
			"endpoints.koding.public",
			"",
			map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"private": "http://127.0.0.1",
					},
				},
				"kdLatest": "http://127.0.0.1/latest-version.txt",
				"debug":    "false",
			},
			true,
		},
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			m := map[string]interface{}{
				"endpoints": map[string]interface{}{
					"koding": map[string]interface{}{
						"public":  "https://koding.com",
						"private": "http://127.0.0.1",
					},
				},
				"kdLatest": "http://127.0.0.1/latest-version.txt",
				"debug":    "false",
			}

			err := configstore.SetFlatKeyValue(m, cas.key, cas.value)

			if !cas.ok {
				if err == nil {
					t.Fatal("want err != nil")
				}
				return
			}

			if !reflect.DeepEqual(m, cas.want) {
				t.Fatalf("got %+v, want %+v", m, cas.want)
			}
		})
	}
}
