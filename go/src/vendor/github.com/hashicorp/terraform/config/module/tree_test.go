package module

import (
	"fmt"
	"os"
	"reflect"
	"strings"
	"testing"

	"github.com/hashicorp/go-getter"
	"github.com/hashicorp/terraform/config"
	"github.com/hashicorp/terraform/helper/copy"
)

func TestTreeChild(t *testing.T) {
	var nilTree *Tree
	if nilTree.Child(nil) != nil {
		t.Fatal("child should be nil")
	}

	storage := testStorage(t)
	tree := NewTree("", testConfig(t, "child"))
	if err := tree.Load(storage, GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	// Should be able to get the root child
	if c := tree.Child([]string{}); c == nil {
		t.Fatal("should not be nil")
	} else if c.Name() != "root" {
		t.Fatalf("bad: %#v", c.Name())
	} else if !reflect.DeepEqual(c.Path(), []string(nil)) {
		t.Fatalf("bad: %#v", c.Path())
	}

	// Should be able to get the root child
	if c := tree.Child(nil); c == nil {
		t.Fatal("should not be nil")
	} else if c.Name() != "root" {
		t.Fatalf("bad: %#v", c.Name())
	} else if !reflect.DeepEqual(c.Path(), []string(nil)) {
		t.Fatalf("bad: %#v", c.Path())
	}

	// Should be able to get the foo child
	if c := tree.Child([]string{"foo"}); c == nil {
		t.Fatal("should not be nil")
	} else if c.Name() != "foo" {
		t.Fatalf("bad: %#v", c.Name())
	} else if !reflect.DeepEqual(c.Path(), []string{"foo"}) {
		t.Fatalf("bad: %#v", c.Path())
	}

	// Should be able to get the nested child
	if c := tree.Child([]string{"foo", "bar"}); c == nil {
		t.Fatal("should not be nil")
	} else if c.Name() != "bar" {
		t.Fatalf("bad: %#v", c.Name())
	} else if !reflect.DeepEqual(c.Path(), []string{"foo", "bar"}) {
		t.Fatalf("bad: %#v", c.Path())
	}
}

func TestTreeLoad(t *testing.T) {
	storage := testStorage(t)
	tree := NewTree("", testConfig(t, "basic"))

	if tree.Loaded() {
		t.Fatal("should not be loaded")
	}

	// This should error because we haven't gotten things yet
	if err := tree.Load(storage, GetModeNone); err == nil {
		t.Fatal("should error")
	}

	if tree.Loaded() {
		t.Fatal("should not be loaded")
	}

	// This should get things
	if err := tree.Load(storage, GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if !tree.Loaded() {
		t.Fatal("should be loaded")
	}

	// This should no longer error
	if err := tree.Load(storage, GetModeNone); err != nil {
		t.Fatalf("err: %s", err)
	}

	actual := strings.TrimSpace(tree.String())
	expected := strings.TrimSpace(treeLoadStr)
	if actual != expected {
		t.Fatalf("bad: \n\n%s", actual)
	}
}

func TestTreeLoad_duplicate(t *testing.T) {
	storage := testStorage(t)
	tree := NewTree("", testConfig(t, "dup"))

	if tree.Loaded() {
		t.Fatal("should not be loaded")
	}

	// This should get things
	if err := tree.Load(storage, GetModeGet); err == nil {
		t.Fatalf("should error")
	}
}

func TestTreeLoad_copyable(t *testing.T) {
	dir := tempDir(t)
	storage := &getter.FolderStorage{StorageDir: dir}
	cfg := testConfig(t, "basic")
	tree := NewTree("", cfg)

	// This should get things
	if err := tree.Load(storage, GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if !tree.Loaded() {
		t.Fatal("should be loaded")
	}

	// This should no longer error
	if err := tree.Load(storage, GetModeNone); err != nil {
		t.Fatalf("err: %s", err)
	}

	// Now we copy the directory, this COPIES symlink values, and
	// doesn't create symlinks themselves. That is important.
	dir2 := tempDir(t)
	os.RemoveAll(dir2)
	defer os.RemoveAll(dir2)
	if err := copy.CopyDir(dir, dir2); err != nil {
		t.Fatalf("err: %s", err)
	}

	// Now copy the configuration
	cfgDir := tempDir(t)
	os.RemoveAll(cfgDir)
	defer os.RemoveAll(cfgDir)
	if err := copy.CopyDir(cfg.Dir, cfgDir); err != nil {
		t.Fatalf("err: %s", err)
	}

	{
		cfg, err := config.LoadDir(cfgDir)
		if err != nil {
			t.Fatalf("err: %s", err)
		}

		tree := NewTree("", cfg)
		storage := &getter.FolderStorage{StorageDir: dir2}

		// This should not error since we already got it!
		if err := tree.Load(storage, GetModeNone); err != nil {
			t.Fatalf("err: %s", err)
		}

		if !tree.Loaded() {
			t.Fatal("should be loaded")
		}
	}
}

func TestTreeLoad_parentRef(t *testing.T) {
	storage := testStorage(t)
	tree := NewTree("", testConfig(t, "basic-parent"))

	if tree.Loaded() {
		t.Fatal("should not be loaded")
	}

	// This should error because we haven't gotten things yet
	if err := tree.Load(storage, GetModeNone); err == nil {
		t.Fatal("should error")
	}

	if tree.Loaded() {
		t.Fatal("should not be loaded")
	}

	// This should get things
	if err := tree.Load(storage, GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if !tree.Loaded() {
		t.Fatal("should be loaded")
	}

	// This should no longer error
	if err := tree.Load(storage, GetModeNone); err != nil {
		t.Fatalf("err: %s", err)
	}

	actual := strings.TrimSpace(tree.String())
	expected := strings.TrimSpace(treeLoadParentStr)
	if actual != expected {
		t.Fatalf("bad: \n\n%s", actual)
	}
}

func TestTreeLoad_subdir(t *testing.T) {
	storage := testStorage(t)
	tree := NewTree("", testConfig(t, "basic-subdir"))

	if tree.Loaded() {
		t.Fatal("should not be loaded")
	}

	// This should error because we haven't gotten things yet
	if err := tree.Load(storage, GetModeNone); err == nil {
		t.Fatal("should error")
	}

	if tree.Loaded() {
		t.Fatal("should not be loaded")
	}

	// This should get things
	if err := tree.Load(storage, GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if !tree.Loaded() {
		t.Fatal("should be loaded")
	}

	// This should no longer error
	if err := tree.Load(storage, GetModeNone); err != nil {
		t.Fatalf("err: %s", err)
	}

	actual := strings.TrimSpace(tree.String())
	expected := strings.TrimSpace(treeLoadSubdirStr)
	if actual != expected {
		t.Fatalf("bad: \n\n%s", actual)
	}
}

func TestTreeModules(t *testing.T) {
	tree := NewTree("", testConfig(t, "basic"))
	actual := tree.Modules()

	expected := []*Module{
		&Module{Name: "foo", Source: "./foo"},
	}

	if !reflect.DeepEqual(actual, expected) {
		t.Fatalf("bad: %#v", actual)
	}
}

func TestTreeName(t *testing.T) {
	tree := NewTree("", testConfig(t, "basic"))
	actual := tree.Name()

	if actual != RootName {
		t.Fatalf("bad: %#v", actual)
	}
}

// This is a table-driven test for tree validation. This is the preferred
// way to test Validate. Non table-driven tests exist historically but
// that style shouldn't be done anymore.
func TestTreeValidate_table(t *testing.T) {
	cases := []struct {
		Name    string
		Fixture string
		Err     string
	}{
		{
			"provider alias in child",
			"validate-alias-good",
			"",
		},

		{
			"undefined provider alias in child",
			"validate-alias-bad",
			"alias must be defined",
		},

		{
			"root module named root",
			"validate-module-root",
			"cannot contain module",
		},

		{
			"grandchild module named root",
			"validate-module-root-grandchild",
			"",
		},
	}

	for i, tc := range cases {
		t.Run(fmt.Sprintf("%d-%s", i, tc.Name), func(t *testing.T) {
			tree := NewTree("", testConfig(t, tc.Fixture))
			if err := tree.Load(testStorage(t), GetModeGet); err != nil {
				t.Fatalf("err: %s", err)
			}

			err := tree.Validate()
			if (err != nil) != (tc.Err != "") {
				t.Fatalf("err: %s", err)
			}
			if err == nil {
				return
			}
			if !strings.Contains(err.Error(), tc.Err) {
				t.Fatalf("err should contain %q: %s", tc.Err, err)
			}
		})
	}
}

func TestTreeValidate_badChild(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-child-bad"))

	if err := tree.Load(testStorage(t), GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if err := tree.Validate(); err == nil {
		t.Fatal("should error")
	}
}

func TestTreeValidate_badChildOutput(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-bad-output"))

	if err := tree.Load(testStorage(t), GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if err := tree.Validate(); err == nil {
		t.Fatal("should error")
	}
}

func TestTreeValidate_badChildOutputToModule(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-bad-output-to-module"))

	if err := tree.Load(testStorage(t), GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if err := tree.Validate(); err == nil {
		t.Fatal("should error")
	}
}

func TestTreeValidate_badChildVar(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-bad-var"))

	if err := tree.Load(testStorage(t), GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if err := tree.Validate(); err == nil {
		t.Fatal("should error")
	}
}

func TestTreeValidate_badRoot(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-root-bad"))

	if err := tree.Load(testStorage(t), GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if err := tree.Validate(); err == nil {
		t.Fatal("should error")
	}
}

func TestTreeValidate_good(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-child-good"))

	if err := tree.Load(testStorage(t), GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	if err := tree.Validate(); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestTreeValidate_notLoaded(t *testing.T) {
	tree := NewTree("", testConfig(t, "basic"))

	if err := tree.Validate(); err == nil {
		t.Fatal("should error")
	}
}

func TestTreeValidate_requiredChildVar(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-required-var"))

	if err := tree.Load(testStorage(t), GetModeGet); err != nil {
		t.Fatalf("err: %s", err)
	}

	err := tree.Validate()
	if err == nil {
		t.Fatal("should error")
	}

	// ensure both variables are mentioned in the output
	errMsg := err.Error()
	for _, v := range []string{"feature", "memory"} {
		if !strings.Contains(errMsg, v) {
			t.Fatalf("no mention of missing variable %q", v)
		}
	}
}

func TestTreeValidate_unknownModule(t *testing.T) {
	tree := NewTree("", testConfig(t, "validate-module-unknown"))

	if err := tree.Load(testStorage(t), GetModeNone); err != nil {
		t.Fatalf("err: %s", err)
	}

	if err := tree.Validate(); err == nil {
		t.Fatal("should error")
	}
}

const treeLoadStr = `
root
  foo (path: foo)
`

const treeLoadParentStr = `
root
  a (path: a)
    b (path: a, b)
`
const treeLoadSubdirStr = `
root
  foo (path: foo)
    bar (path: foo, bar)
`
