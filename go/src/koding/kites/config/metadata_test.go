package config_test

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"koding/kites/config"

	"github.com/boltdb/bolt"
)

func TestDumpToBolt(t *testing.T) {
	cases := map[string]struct {
		want, got config.Metadata
	}{
		"simple kite.key config": {
			config.Metadata{
				"konfig": &config.Konfig{
					KiteKeyFile: "/tmp/kite.key",
				},
			},
			config.Metadata{
				"konfig": &config.Konfig{},
			},
		},
		"generic value": {
			config.Metadata{
				"klient.tunnel.services": map[string]interface{}{
					"service 1": "ssh",
					"service 2": "kite",
				},
			},
			config.Metadata{
				"klient.tunnel.services": nil,
			},
		},
		"multiple databases": {
			config.Metadata{
				"database1.bucket.key": map[string]interface{}{
					"config #1": "value #1",
					"config #2": "value #2",
				},
				"database2.bucket.key": map[string]interface{}{
					"config #3": "value #3",
					"config #4": "value #4",
				},
			},
			config.Metadata{
				"database1.bucket.key": nil,
				"database2.bucket.key": nil,
			},
		},
		"multiple databases with multiple buckets": {
			config.Metadata{
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
			config.Metadata{
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

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			err := config.DumpToBolt(dir, cas.want)

			if err != nil {
				t.Fatalf("DumpToBolt()=%s", err)
			}

			err = ReadFromBolt(dir, cas.got)

			if err != nil {
				t.Fatalf("ReadFromBolt()=%s", err)
			}

			if !reflect.DeepEqual(cas.got, cas.want) {
				t.Fatalf("got %+v != want %+v", cas.got, cas.want)
			}
		})
	}
}

// TODO(rjeczalik): merge with DumpToBult - create BoltMetadata struct.
func ReadFromBolt(home string, m config.Metadata) error {
	var de config.DumpError

	if home == "" {
		home = config.KodingHome()
	}

	for key, value := range m {
		var file, bucket, keyValue string

		switch s := strings.SplitN(key, ".", 3); len(s) {
		case 1:
			file = s[0]
			bucket = s[0]
			keyValue = s[0]
		case 2:
			file = s[0]
			bucket = s[1]
			keyValue = s[1]
		case 3:
			file = s[0]
			bucket = s[1]
			keyValue = s[2]
		}

		db, err := config.NewBoltCache(&config.CacheOptions{
			File: filepath.Join(home, file+".bolt"),
			BoltDB: &bolt.Options{
				Timeout: 5 * time.Second,
			},
			Bucket: []byte(bucket),
		})

		if err != nil {
			de.Errs = append(de.Errs, &config.MetadataError{
				Key: key,
				Err: err,
			})
			continue
		}

		if value == nil {
			v := make(map[string]interface{})
			value = &v
			m[key] = v
		}

		err = db.GetValue(keyValue, value)

		if e := db.Close(); e != nil && err == nil {
			err = e
		}

		if err != nil {
			de.Errs = append(de.Errs, &config.MetadataError{
				Key: key,
				Err: err,
			})
			continue
		}
	}

	if len(de.Errs) == 0 {
		return nil
	}

	return &de
}
