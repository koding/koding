package configstore_test

import (
	"io/ioutil"
	"os"
	"reflect"
	"testing"

	"koding/kites/config"
	"koding/kites/config/configstore"
)

func TestDumpToBolt(t *testing.T) {
	cases := map[string]struct {
		want, got configstore.Metadata
	}{
		"simple kite.key config": {
			configstore.Metadata{
				"konfig": &config.Konfig{
					KiteKeyFile: "/tmp/kite.key",
				},
			},
			configstore.Metadata{
				"konfig": &config.Konfig{},
			},
		},
		"generic value": {
			configstore.Metadata{
				"klient.tunnel.services": map[string]interface{}{
					"service 1": "ssh",
					"service 2": "kite",
				},
			},
			configstore.Metadata{
				"klient.tunnel.services": nil,
			},
		},
		"multiple databases": {
			configstore.Metadata{
				"database1.bucket.key": map[string]interface{}{
					"config #1": "value #1",
					"config #2": "value #2",
				},
				"database2.bucket.key": map[string]interface{}{
					"config #3": "value #3",
					"config #4": "value #4",
				},
			},
			configstore.Metadata{
				"database1.bucket.key": nil,
				"database2.bucket.key": nil,
			},
		},
		"multiple databases with multiple buckets": {
			configstore.Metadata{
				"database1.bucket1.key": map[string]interface{}{
					"config": "value",
				},
				"database1.bucket2.key": map[string]interface{}{
					"config": "value",
				},
				"database2.bucket1.key": map[string]interface{}{
					"config": "value",
				},
				"database2.bucket2.key": map[string]interface{}{
					"config": "value",
				},
			},
			configstore.Metadata{
				"database1.bucket1.key": nil,
				"database1.bucket2.key": nil,
				"database2.bucket1.key": nil,
				"database2.bucket2.key": nil,
			},
		},
	}

	dir, err := ioutil.TempDir("", "config_test")
	if err != nil {
		t.Fatalf("TempDir()=%s", err)
	}
	defer os.RemoveAll(dir)

	c := &configstore.Client{
		Home: dir,
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			err := c.WriteMetadata(cas.want)

			if err != nil {
				t.Fatalf("WriteMetadata()=%s", err)
			}

			err = c.ReadMetadata(cas.got)

			if err != nil {
				t.Fatalf("ReadMetadata()=%s", err)
			}

			if !reflect.DeepEqual(cas.got, cas.want) {
				t.Fatalf("got %+v != want %+v", cas.got, cas.want)
			}
		})
	}
}
