package app_test

import (
	"encoding/json"
	"flag"
	"io/ioutil"
	"path/filepath"
	"testing"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/stack/provider/providertest"
	"koding/klientctl/app"
	"koding/klientctl/app/mixin"

	_ "koding/kites/kloud/kloud" // required for provider.Desc()
)

var update = flag.Bool("update-golden", false, "")

var (
	desc = provider.Desc() // requires go/build.sh so genimport.go is generated
	mix  = mixin.New([]byte(`machine:
  koding_always_on: true
cloudinit:
  ssh_authorized_keys:
    - ssh-rsa AAAAB3NzaC1yc2EA... koding-350298856
  runcmd:
    - echo "hello world!" >> /helloworld.txt`))
)

func TestReplaceUserData(t *testing.T) {
	cases := map[string]struct {
		desc *stack.Description
	}{
		"testdata/aws.json":       {desc["aws"]},
		"testdata/azure.json":     {desc["azure"]},
		"testdata/do.json":        {desc["digitalocean"]},
		"testdata/google.json":    {desc["google"]},
		"testdata/softlayer.json": {desc["softlayer"]},
	}

	for file, cas := range cases {
		t.Run(filepath.Base(file), func(t *testing.T) {
			if *update {
				if err := updateGolden(file, cas.desc); err != nil {
					t.Fatalf("updateGolden()=%s", err)
				}
				return
			}

			tmpl, err := ioutil.ReadFile(file)
			if err != nil {
				t.Fatalf("ReadFile()=%s", err)
			}

			v, err := app.ReplaceUserData(string(tmpl), mix, cas.desc)
			if err != nil {
				t.Fatalf("ReplaceUserData()=%s", err)
			}

			got, err := json.Marshal(v)
			if err != nil {
				t.Fatalf("Marshal()=%s", err)
			}

			want, err := ioutil.ReadFile(file + ".golden")
			if err != nil {
				t.Fatalf("ReadFile()=%s", err)
			}

			if err := providertest.Equal(string(got), string(want), nil); err != nil {
				t.Fatalf("Equal()=%s", err)
			}
		})
	}
}

func updateGolden(file string, desc *stack.Description) error {
	p, err := ioutil.ReadFile(file)
	if err != nil {
		return err
	}

	t, err := app.ReplaceUserData(string(p), mix, desc)
	if err != nil {
		return err
	}

	p, err = json.MarshalIndent(t, "", "\t")
	if err != nil {
		return err
	}

	return ioutil.WriteFile(file+".golden", p, 0644)
}
