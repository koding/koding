package configstore

import (
	"bytes"
	"encoding/json"
	"fmt"
	"koding/kites/config"
	"koding/tools/util"
	"path/filepath"
	"strings"
	"time"

	"github.com/boltdb/bolt"
)

// Metadata represents generic configuration object, that can be applied
// to multiple configuration sources at once.
//
// For instance WriteMetadata function is used to dump metadata
// to a BoltDB files. For more details see WriteMetadata documentation.
type Metadata map[string]interface{}

// ID reads Koding base url from m.konfig.endpoints.koding.public and
// creates an ID out of it.
//
// If the Koding base url is missing in the metadata it returns empty string.
func (m Metadata) ID() string {
	konfig, err := m.readKonfig()
	if err != nil {
		return ""
	}
	return konfig.ID()
}

func (m Metadata) readKonfig() (*config.Konfig, error) {
	konfig, ok := m["konfig"].(*config.Konfig)
	if !ok {
		var metadata struct {
			Konfig config.Konfig `json:"konfig"`
		}
		p, err := json.Marshal(m)
		if err != nil {
			return nil, err
		}
		if err := json.Unmarshal(p, &metadata); err != nil {
			return nil, err
		}
		konfig = &metadata.Konfig
	}

	return konfig, konfig.Valid()
}

// MetadataError is an error writing single metadata key.
type MetadataError struct {
	Key string
	Err error
}

// Error implements the built-in error interface.
func (me *MetadataError) Error() string {
	return me.Key + ": " + me.Err.Error()
}

// WriteMetadataError describes error while dumping metadata.
type WriteMetadataError struct {
	Errs []*MetadataError
}

// Error implements the built-in error interface.
func (de *WriteMetadataError) Error() string {
	var buf bytes.Buffer

	buf.WriteString("Failure dumping keys:\n\n")

	for _, me := range de.Errs {
		fmt.Fprintf(&buf, "\t* %s\n", me)
	}

	return buf.String()
}

// WriteMetadata function is used to dump metadata to a BoltDB files
// in the following manner:
//
//   - if the key does not contain a dot, it is treated as
//     both a file name and bucket name and the file path is
//     constructed like: $KODING_HOME/$KEY.bolt
//   - if the above $KEY is different than "konfig" than an ID
//     is also appended to the file name, so the full path
//     to the database will look like: $KODING_HOME/$KEY.$ID.bolt
//     the ID is uniquely created per Koding Base URL
//     of the configuration
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
//   m := configstore.Metadata{
//       "konfig": &config.Konfig{
//           Endpoints: config.NewEndpoint("https://koding.com"),
//           KiteKey:   must(ioutil.ReadFile("/home/user/.kite/development.kite")),
//       },
//       "kd": map[string]interface{}{
//           "foo": "bar",
//       },
//   }
//
// WriteMetadata will then create two bolt files and write the contents:
//
//   - to "konfig" bucket in $KODING_HOME/konfig.bolt file
//   - to "kd" bucket in $KODING_HOME/kd.79f57bf6.bolt file
//
func (c *Client) WriteMetadata(m Metadata) error {
	fn := func(cache *config.Cache, key string, value interface{}) error {
		return cache.SetValue(key, value)
	}

	return c.commitMetadata(m, fn)
}

// ReadMetadata reads metadata from multiple BoltDB files, pointed by
// the metadata keys.
//
// See WriteMetadata inline docs to see how it finds the files.
func (c *Client) ReadMetadata(m Metadata) error {
	fn := func(cache *config.Cache, key string, value interface{}) error {
		return cache.GetValue(key, value)
	}

	return c.commitMetadata(m, fn)
}

type metadataCommitFunc func(cache *config.Cache, key string, value interface{}) error

func (c *Client) commitMetadata(m Metadata, fn metadataCommitFunc) error {
	var de WriteMetadataError

	// Try to read ID for Koding Base URL from the metadata, if not available
	// read currently used one from konfig.bolt. If both fails, do not
	// use ID at all.
	id := m.ID()
	if id == "" {
		// Best-effort attempt to rea
		if k, err := c.Used(); err == nil {
			id = k.ID()
		}
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

		// The konfig.bolt metadata is global for all koding
		// deployments.
		if file != "konfig" && id != "" {
			file = file + "." + id + ".bolt"
		} else {
			file = file + ".bolt"
		}

		opts := &config.CacheOptions{
			File: filepath.Join(c.home(), file),
			BoltDB: &bolt.Options{
				Timeout: 5 * time.Second,
			},
			Bucket: []byte(bucket),
			Owner:  c.owner(),
		}

		db, err := config.NewBoltCache(opts)

		if err != nil {
			de.Errs = append(de.Errs, &MetadataError{
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

		err = nonil(fn(db, keyValue, value), db.Close(), util.Chown(opts.File, c.owner().User))

		if err != nil {
			de.Errs = append(de.Errs, &MetadataError{
				Key: key,
				Err: err,
			})
		}
	}

	if len(de.Errs) == 0 {
		return nil
	}

	return &de
}

// FixOwner changes ownership of files and directories rooted
// at home to the owner user, if it's not a root.
func (c *Client) FixOwner() error {
	// Don't change owner
	if c.owner().User.Uid == "0" {
		return nil
	}

	return nonil(
		util.ChownAll(c.home(), c.owner().User),
		util.ChownAll(c.mounts(), c.owner().User),
	)
}

func FixOwner() error                { return DefaultClient.FixOwner() }
func WriteMetadata(m Metadata) error { return DefaultClient.WriteMetadata(m) }
func ReadMetadata(m Metadata) error  { return DefaultClient.ReadMetadata(m) }
