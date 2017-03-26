package metadata_test

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/metadata"
	"path/filepath"
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
	cases := map[string]string{
		"testdata/ssh_authorized_keys.yml": "testdata/ssh_authorized_keys.yml.golden",
		"testdata/users.yml":               "testdata/users.yml.golden",
		"testdata/write_files.yml":         "testdata/write_files.yml.golden",
	}

	for yml, golden := range cases {
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

			want, err := parseCloudInit(golden)
			if err != nil {
				t.Fatalf("ParseCloudInit()=%s", err)
			}

			metadata.Merge(testdata, got)

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
