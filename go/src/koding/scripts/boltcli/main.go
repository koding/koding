package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"koding/kites/config/configstore"
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"time"

	"github.com/boltdb/bolt"
)

const usage = `usage: boltcli [command] <file.bolt> [args...]

If path is relative, boltdump in addition to current working directory
will also look for a file in path pointed by $KODING_HOME environmental
variable.

If $KODING_HOME is empty or unset, $HOME/.config/koding is used by default.

Commands

get <file.bolt>

  $ boltcli get konfig
  $ boltcli get konfig.bolt
  $ boltcli get ~/.config/koding/konfig.bolt

All three above commands have the same effect if KODING_HOME is empty or unset.

set <file.bolt> <path> <value>

  $ boltcli set konfig.bolt bucket.key.field value
`

var home = must(user.Current()).(*user.User).HomeDir

var basher = strings.NewReplacer("~/", home+"/")

func must(v interface{}, err error) interface{} {
	if err != nil {
		panic(err)
	}
	return v
}

func die(args ...interface{}) {
	fmt.Fprintln(os.Stderr, args...)
	os.Exit(1)
}

func lookup(file string) (string, error) {
	file = basher.Replace(file)

	_, err := os.Stat(file)
	if err == nil {
		return file, nil
	}
	if filepath.IsAbs(file) {
		return "", err
	}

	kodingHome := os.Getenv("KODING_HOME")
	if kodingHome == "" {
		kodingHome = filepath.Join(home, ".config", "koding")
	}

	for _, file := range []string{
		filepath.Join(kodingHome, file),
		filepath.Join(kodingHome, file+".bolt"),
	} {
		if _, err = os.Stat(file); err == nil {
			return file, nil
		}
	}

	return "", err
}

func get(db *bolt.DB) error {
	all := make(map[string]map[string]interface{})

	fn := func(tx *bolt.Tx) error {
		return tx.ForEach(func(name []byte, bucket *bolt.Bucket) error {
			b := make(map[string]interface{})

			all[string(name)] = b

			cur := bucket.Cursor()

			for key, value := cur.First(); key != nil && value != nil; key, value = cur.Next() {
				// TODO(rjeczalik): use json.RawMessage and do not extra decode after we
				// switch to go1.8 - related:
				//
				//   github.com/golang/go/issues/14493
				//
				var v interface{}

				if err := json.Unmarshal(value, &v); err != nil {
					return err
				}

				b[string(key)] = v
			}

			return nil
		})
	}

	if err := db.View(fn); err != nil {
		return err
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")
	return enc.Encode(all)
}

func set(db *bolt.DB, path, value string) error {
	s := strings.SplitN(path, ".", 3)
	if len(s) < 3 {
		return errors.New(`invalid path argument format: expected at least "bucket.key.fields"`)
	}

	bucket := []byte(s[0])
	key := []byte(s[1])
	fields := s[2]

	return db.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket(bucket)
		if b == nil {
			return fmt.Errorf("bucket %q was not found", bucket)
		}

		m := make(map[string]interface{})

		if p := b.Get(key); len(p) != 0 {
			if err := json.Unmarshal(p, &m); err != nil {
				return err
			}
		}

		if err := configstore.SetFlatKeyValue(m, fields, value); err != nil {
			return err
		}

		p, err := json.Marshal(m)
		if err != nil {
			return err
		}

		return b.Put(key, p)
	})
}

func main() {
	flag.CommandLine.Usage = func() {
		fmt.Fprintln(os.Stderr, usage)
	}

	flag.Parse()
	if flag.NArg() < 2 {
		die(usage)
	}

	file, err := lookup(flag.Arg(1))
	if err != nil {
		die(err)
	}

	db, err := bolt.Open(file, 0, &bolt.Options{
		Timeout:  2 * time.Second,
		ReadOnly: flag.Arg(0) == "get",
	})
	if err != nil {
		die(err)
	}

	switch flag.Arg(0) {
	case "get":
		err = get(db)
	case "set":
		if flag.NArg() != 4 {
			die(usage)
		}

		err = set(db, flag.Arg(2), flag.Arg(3))
	default:
		die("unknown command: " + flag.Arg(0))
	}

	if err != nil {
		die(err)
	}
}
