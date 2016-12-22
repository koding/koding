package index

import (
	"io"
	"io/ioutil"
	"math/rand"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// filetree defines a simple directory structure that will be created for test
// purposes. The values of this map stores file sizes.
var filetree = map[string]int64{
	"a.txt":        128,
	"b.bin":        300 * 1024,
	"c/ca.txt":     2 * 1024,
	"c/cb.bin":     1024 * 1024,
	"d/da.txt":     5 * 1024,
	"d/db.txt":     256,
	"d/dc/dca.txt": 3 * 1024,
	"d/dc/dcb.txt": 1024,
}

func generateTree() (root string, clean func(), err error) {
	root, err = ioutil.TempDir("", "mount.index")
	if err != nil {
		return "", nil, err
	}
	clean = func() { os.RemoveAll(root) }

	for file, size := range filetree {
		file = filepath.Join(root, filepath.FromSlash(file))
		if err = os.MkdirAll(filepath.Dir(file), 0777); err != nil {
			clean()
			return "", nil, err
		}

		lr := io.LimitReader(rand.New(rand.NewSource(time.Now().UnixNano())), size)
		content, err := ioutil.ReadAll(lr)
		if err != nil {
			clean()
			return "", nil, err
		}

		if err := ioutil.WriteFile(file, content, 0666); err != nil {
			clean()
			return "", nil, err
		}
	}

	return root, clean, nil
}

func TestNewIndexPath(t *testing.T) {
	root, clean, err := generateTree()
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer clean()
	t.Log(root)

	_ = root
	t.Skip("not implemented")
}
