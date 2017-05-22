package metadata_test

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"io/ioutil"
	"koding/kites/kloud/metadata"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/kylelemons/godebug/pretty"
)

var update = flag.Bool("update-golden", false, "Update golden files.")

var testdata = metadata.NewCloudInit(&metadata.CloudConfig{
	Metadata: "metadata",
	Userdata: "userdata",
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
		"testdata/conflict_write_files.yml": {
			conflict: []string{"write_files", "1", "path"},
		},
	}

	for yml, cas := range cases {
		t.Run(filepath.Base(yml), func(t *testing.T) {
			if *update {
				if !strings.HasPrefix(filepath.Base(yml), "conflict_") {
					if err := updateGolden(yml); err != nil {
						t.Fatal(err)
					}
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
		return errors.New(pretty.Compare(got, want))
	}

	return nil
}

func updateGolden(yml string) error {
	ci, err := parseCloudInit(yml)
	if err != nil {
		return errors.New("ParseCloudInit()=" + err.Error())
	}

	if err := metadata.Merge(testdata, ci); err != nil {
		return err
	}

	if err := ioutil.WriteFile(yml+".golden", ci.Bytes(), 0644); err != nil {
		return errors.New("WriteFile()=" + err.Error())
	}

	return nil
}
