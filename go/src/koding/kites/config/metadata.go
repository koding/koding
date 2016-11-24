package config

import (
	"bytes"
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/boltdb/bolt"
)

// Metadata represents generic configuration object, that can be applied
// to multiple configuration sources at once.
//
// For instance DumpToBolt function is used to dump metadata
// to a BoltDB files. For more details see DumpToBolt documentation.
type Metadata map[string]interface{}

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
//       "konfig": &config.Konfig{
//           KiteKeyFile": "/home/user/.kite/development.kite",
//       },
//   }
//
// DumpToBolt will then write it to $KODING_HOME/konfig.bolt under "koding"
// bucket.
//
// If home is empty, KodingHome() will be used instead.
//
// If owner is nil, CurrentUser will be used instead.
func DumpToBolt(home string, m Metadata, owner *user.User) error {
	var de DumpError

	if home == "" {
		home = KodingHome()
	}

	if owner == nil {
		owner = CurrentUser
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

		opts := &CacheOptions{
			File: filepath.Join(home, file+".bolt"),
			BoltDB: &bolt.Options{
				Timeout: 5 * time.Second,
			},
			Bucket: []byte(bucket),
			Owner:  owner,
		}

		db, err := NewBoltCache(opts)

		if err != nil {
			de.Errs = append(de.Errs, &MetadataError{
				Key: key,
				Err: err,
			})
			continue
		}

		err = nonil(db.SetValue(keyValue, value), db.Close(), chown(opts.File, owner))

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

func chown(file string, u *user.User) error {
	if u == nil {
		return nil
	}

	uid, err := strconv.Atoi(u.Uid)
	if err != nil {
		return err
	}

	gid, err := strconv.Atoi(u.Gid)
	if err != nil {
		return err
	}

	return os.Chown(file, uid, gid)
}

func chownAll(dir string, u *user.User) error {
	return filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		return chown(dir, u)
	})
}

// FixOwner changes ownership of files and directories rooted
// at home to the owner user, if it's not a root.
//
// If home is empty, KodingHome() is used instead.
//
// If owner is nil, CurrentUser is used instead.
func FixOwner(home string, owner *user.User) error {
	if home == "" {
		home = KodingHome()
	}

	if owner == nil {
		owner = CurrentUser
	}

	// Don't change owner
	if owner.Uid == "0" {
		return nil
	}

	return chownAll(home, owner)
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}
