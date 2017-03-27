package metadata_test

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/metadata"
	"path/filepath"
	"reflect"
	"testing"
)

var update = flag.Bool("update-golden", false, "Update golden files.")

var testdata = metadata.NewCloudInit(&metadata.CloudConfig{
	Username:  "johndoe",
	Metadata:  "metadata",
	Userdata:  "userdata",
	KiteKey:   "kitekey",
	Provision: "provision",
})

func parseCloudInit(file string) (metadata.CloudInit, error) {
	p, err := ioutil.ReadFile(file)
	if err != nil {
		return nil, err
	}

	return metadata.ParseCloudInit(p)
}

func TestCloudInit(t *testing.T) {
	cases := map[string]struct {
		golden   string
		conflict []string
	}{
		"testdata/ssh_authorized_keys.yml": {
			golden:   "testdata/ssh_authorized_keys.yml.golden",
			conflict: nil,
		},
		"testdata/users.yml": {
			golden:   "testdata/users.yml.golden",
			conflict: nil,
		},
		"testdata/write_files.yml": {
			golden:   "testdata/write_files.yml.golden",
			conflict: nil,
		},
		"testdata/conflict_output.yml": {
			conflict: []string{"output", "all"},
		},
		"testdata/conflict_users.yml": {
			conflict: []string{"users", "1", "name"},
		},
		"testdata/conflict_write_files.yml": {
			conflict: []string{"write_files", "1", "path"},
		},
	}

	for yml, cas := range cases {
		t.Run(filepath.Base(yml), func(t *testing.T) {
			if *update {
				ci, err := parseCloudInit(yml)
				if err != nil {
					t.Fatalf("ParseCloudInit()=%s", err)
				}

				metadata.Merge(testdata, ci)

				if err := ioutil.WriteFile(yml+".golden", ci.Bytes(), 0644); err != nil {
					t.Fatalf("WriteFile()=%s", err)
				}

				return
			}

			got, err := parseCloudInit(yml)
			if err != nil {
				t.Fatalf("ParseCloudInit()=%s", err)
			}

			err = metadata.Merge(testdata, got)
			if cas.conflict != nil {
				me, ok := err.(*metadata.MergeError)
				if !ok {
					t.Fatalf("got %T, want %T", err, (*metadata.MergeError)(nil))
				}

				if !reflect.DeepEqual(me.Path, cas.conflict) {
					t.Fatalf("got %v, want %v", me.Path, cas.conflict)
				}

				return
			}

			if err != nil {
				t.Fatalf("Merge()=%s", err)
			}

			want, err := parseCloudInit(cas.golden)
			if err != nil {
				t.Fatalf("ParseCloudInit()=%s", err)
			}

			if err := equal(got, want); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func equal(got, want metadata.CloudInit) error {
	pgot, err := json.MarshalIndent(got, "", "\t")
	if err != nil {
		return err
	}

	pwant, err := json.MarshalIndent(want, "", "\t")
	if err != nil {
		return err
	}

	if bytes.Compare(pgot, pwant) != 0 {
		return fmt.Errorf("got:\n%s\n\nwant:\n%s\n", pgot, pwant)
	}

	return nil
}
