package config

import (
	"bytes"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/boltdb/bolt"
)

// Metadata represents generic configuration object, that can be applied
// to multiple configuration sources at once.
//
// For instance DumpToBolt function is used to dump metadata
// to a BoltDB files. For more details see DumpToBolt documentation.
type Metadata map[string]json.RawMessage

// MetadataError is an error writing single metadata key.
type MetadataError struct {
	Key string
	Err error
}

// Error implements the built-in error interface.
func (me *MetadataError) Error() string {
	return me.Key + ": " + me.Err.Error()
}

// DumpError describes error while dumping metadata.
type DumpError struct {
	Errs []*MetadataError
}

// Error implements the built-in error interface.
func (de *DumpError) Error() string {
	var buf bytes.Buffer

	buf.WriteString("Failure dumping keys:\n\n")

	for _, me := range de.Errs {
		fmt.Fprintf(&buf, "\t* %s", me.Error())
	}

	return buf.String()
}

// DumpToBolt function is used to dump metadata to a BoltDB files
// in the following manner:
//
//   - if the key does not contain a dot, it is treated as
//     both a file name and bucket name and the file path is
//     constructed like: $KODING_HOME/$KEY.bolt
//   - if the key do contain a dot, the part to the dot is treated
//     as a file name while the rest defines a bucket name
//
// Metadata can be used to overwrite or set values that are read later on
// by config.NewKonfig function.
//
// Example
//
// In order to set or overwrite kite.key file's path content, apply the
// following metadata:
//
//   m := config.Metadata{
//       "konfig": {
//           "kiteKeyFile": "/home/user/.kite/development.kite",
//       },
//   }
//
// DumpToBolt will then write it to $KODING_HOME/konfig.bolt under "koding"
// bucket.
//
// If home is empty, KodingHome() will be used instead.
func DumpToBolt(home string, m Metadata) error {
	var de DumpError

	if home == "" {
		home = KodingHome()
	}

	for key, value := range m {
		s := strings.SplitN(key, ".", 3)
		file, bucket, keyValue := s[0], s[1], s[2]

		if bucket == "" {
			bucket = file
		}

		if keyValue == "" {
			keyValue = file
		}

		db, err := NewBoltCache(&CacheOptions{
			File: filepath.Join(home, file+".bolt"),
			BoltDB: &bolt.Options{
				Timeout: 5 * time.Second,
			},
			Bucket: []byte(bucket),
		})

		if err != nil {
			de.Errs = append(de.Errs, &MetadataError{
				Key: key,
				Err: err,
			})
			continue
		}

		err = db.Set(keyValue, string(value))

		if e := db.Close(); e != nil && err == nil {
			err = e
		}

		if err != nil {
			de.Errs = append(de.Errs, &MetadataError{
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
