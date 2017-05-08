package indextest

import (
	"fmt"
	"io"
	"io/ioutil"
	"math/rand"
	"os"
	"path/filepath"
	"time"

	"koding/klient/machine/index"

	"github.com/djherbis/times"
)

// Compare is a helper function that compares the content of two provided
// directories. The detected changes will be returned as index change slice.
// First argument is treated as base index data.
func Compare(rootA, rootB string) (cs index.ChangeSlice, err error) {
	idx, err := index.NewIndexFiles(rootA, nil)
	if err != nil {
		return nil, err
	}

	// Merge ony adds files so it will make remote add instead of local delete
	// we need to fix this.
	mra := index.ChangeMetaAdd | index.ChangeMetaRemote
	cst, err := idx.Merge(rootB, nil)
	if err != nil {
		return nil, err
	}

	for _, c := range cst {
		if c.Meta()&mra == mra {
			c = index.NewChange(c.Path(), index.PriorityLow, index.ChangeMetaRemove)
		}
		cs = append(cs, c)
	}

	return cs, nil
}

// GenerateMirrorTrees generates two identical file trees using GenerateTree
// helper function. This function ensures that ComparePath of two generated
// directories will not produce any index changes.
func GenerateMirrorTrees(filetree map[string]int64) (string, string, func(), error) {
	rootA, cleanA, err := GenerateTree(filetree)
	if err != nil {
		return "", "", nil, err
	}

	rootB, cleanB, err := GenerateTree(filetree)
	if err != nil {
		cleanA()
		return "", "", nil, err
	}

	clean := func() {
		cleanB()
		cleanA()
	}

	for path := range filetree {
		if err := makeSimilarTimes(rootA, rootB, path); err != nil {
			clean()
			return "", "", nil, err
		}
	}

	cs, err := Compare(rootA, rootB)
	if len(cs) != 0 {
		err = fmt.Errorf("generated paths are not identical: %v", cs)
	}

	if err != nil {
		clean()
		return "", "", nil, err
	}

	return rootA, rootB, clean, nil
}

func makeSimilarTimes(rootA, rootB, path string) error {
	t, err := times.Stat(filepath.Join(rootA, path))
	if err != nil {
		return err
	}

	if err := os.Chtimes(filepath.Join(rootB, path), t.AccessTime(), t.ModTime()); err != nil {
		return err
	}

	// Changing mtime also modifies ctime. Files stored inside rootA may have
	// different mtime and ctime values so it's needed to Chtimes them as well.
	return os.Chtimes(filepath.Join(rootA, path), t.AccessTime(), t.ModTime())
}

// GenerateTree generates a file tree inside a temporary directory. The filetree
// map has relative paths as keys and file size as value. Clean function must
// be called in order to clean up resources.
func GenerateTree(filetree map[string]int64) (root string, clean func(), err error) {
	root, err = ioutil.TempDir("", "mount.index")
	if err != nil {
		return "", nil, err
	}
	clean = func() { os.RemoveAll(root) }

	for file, size := range filetree {
		if err := AddDir(file)(root); err != nil {
			clean()
			return "", nil, err
		}
		if err := WriteFile(file, size)(root); err != nil {
			clean()
			return "", nil, err
		}
	}

	return root, clean, nil
}

// AddDir creates a functor which, when invoked on provided root, will create
// new directory specified by file argument.
func AddDir(file string) func(string) error {
	return func(root string) error {
		defer Sync()

		dir := filepath.Join(root, filepath.FromSlash(file))
		if filepath.Ext(dir) != "" {
			dir = filepath.Dir(dir)
		}

		return os.MkdirAll(dir, 0777)
	}
}

// WriteFile creates a functor which, when invoked on provided root, will create
// a new file specified by file and size arguments. The content of the file will
// be randomized.
func WriteFile(file string, size int64) func(string) error {
	return func(root string) error {
		defer Sync()

		if filepath.Ext(file) == "" {
			return nil
		}

		lr := io.LimitReader(rand.New(rand.NewSource(time.Now().UnixNano())), size)
		content, err := ioutil.ReadAll(lr)
		if err != nil {
			return err
		}

		file := filepath.Join(root, filepath.FromSlash(file))
		return ioutil.WriteFile(file, content, 0666)
	}
}

// RmAllFile creates a functor which, when invoked on provided root, will
// remove all files inside in directory specified by file argument. If the
// argument describes regural file it will be removed.
func RmAllFile(file string) func(string) error {
	return func(root string) error {
		defer Sync()

		return os.RemoveAll(filepath.Join(root, filepath.FromSlash(file)))
	}
}

// MvFile creates a functor which, when invoked on provided root, will move
// oldpath file to newpath file.
func MvFile(oldpath, newpath string) func(string) error {
	return func(root string) error {
		defer Sync()

		var (
			oldpath = filepath.Join(root, filepath.FromSlash(oldpath))
			newpath = filepath.Join(root, filepath.FromSlash(newpath))
		)

		return os.Rename(oldpath, newpath)
	}
}

// ChmodFile creates a functor which, when invoked on provided root, will change
// mode bits of the file specified by file argument.
func ChmodFile(file string, mode os.FileMode) func(string) error {
	return func(root string) error {
		defer Sync()

		return os.Chmod(filepath.Join(root, filepath.FromSlash(file)), mode)
	}
}
