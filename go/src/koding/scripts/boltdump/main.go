package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"

	"github.com/boltdb/bolt"
)

const usage = `usage: boltdump <file.bolt>

If path is relative, boltdump in addition to current working directory
will also look for a file in path pointed by $KODING_HOME environmental
variable.

If $KODING_HOME is empty or unset, $HOME/.config/koding is used by default.

Example usage

  $ boltdump konfig
  $ boltdump konfig.bolt
  $ boltdump ~/.config/koding/konfig.bolt

All three above commands have the same effect if KODING_HOME is empty or unset.
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

func main() {
	flag.CommandLine.Usage = func() {
		fmt.Fprintln(os.Stderr, usage)
	}

	flag.Parse()
	if flag.NArg() != 1 {
		die(usage)
	}

	file, err := lookup(flag.Arg(0))
	if err != nil {
		die(err)
	}

	db, err := bolt.Open(file, 0, nil)
	if err != nil {
		die(err)
	}

	all := make(map[string]map[string]interface{})

	dump := func(tx *bolt.Tx) error {
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

	if err := db.View(dump); err != nil {
		die(err)
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")
	enc.Encode(all)
}
