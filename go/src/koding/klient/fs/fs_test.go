package fs_test

import (
	"io/ioutil"
	"os"
	"os/user"
	"path/filepath"
	"testing"

	"koding/klient/fs"
)

func TestAbs(t *testing.T) {
	root, err := testTree()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	testFS := fs.FS{
		User: &user.User{HomeDir: root},
	}

	tests := map[string]struct {
		Path    string
		AbsPath string
		IsDir   bool
		Exist   bool
		Valid   bool
	}{
		"already absolute": {
			Path:    filepath.Join(root, "test_dir"),
			AbsPath: filepath.Join(root, "test_dir"),
			IsDir:   true,
			Exist:   true,
			Valid:   true,
		},
		"tilde root": {
			Path:    "~" + string(os.PathSeparator),
			AbsPath: root,
			IsDir:   true,
			Exist:   true,
			Valid:   true,
		},
		"tilde file": {
			Path:    filepath.Join("~", "test_file"),
			AbsPath: filepath.Join(root, "test_file"),
			IsDir:   false,
			Exist:   true,
			Valid:   true,
		},
		"does not exist": {
			Path:    filepath.Join("~", "no_exist"),
			AbsPath: filepath.Join(root, "no_exist"),
			IsDir:   false,
			Exist:   false,
			Valid:   true,
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			absPath, isDir, exist, err := testFS.Abs(test.Path)
			if (err == nil) != test.Valid {
				t.Fatalf("want valid test = %t; got err = %v", test.Valid, err)
			}

			if absPath != test.AbsPath {
				t.Errorf("want absolute path = %q; got %q", test.AbsPath, absPath)
			}
			if isDir != test.IsDir {
				t.Errorf("want is dir = %t; got %t", test.IsDir, isDir)
			}
			if exist != test.Exist {
				t.Errorf("want exist = %t; got %t", test.Exist, exist)
			}
		})
	}
}

// testTree creates a temporary directory with `test_dir` file and `test_dir`
// folder inside.
func testTree() (root string, err error) {
	tmpDir, err := ioutil.TempDir("", "fs")
	if err != nil {
		return "", err
	}

	path := filepath.Join(tmpDir, "test_")
	if err := os.Mkdir(path+"dir", 0755); err != nil {
		return "", err
	}

	if err := ioutil.WriteFile(path+"file", []byte("koding"), 0644); err != nil {
		return "", err
	}

	return tmpDir, err
}
