package index

import (
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

const tempIndexDirPrefix = "koding_index_"

// Cached allows to cache and reuse previously created index.
type Cached struct {
	// Function used to retrieve temporary directory. If nil, os.TempDir will be
	// used.
	TempDir func() string
}

// GetCachedIndex returns index that describes the current directory state. This
// function stores the resulting index in temporary file in order to not
// recompute it each time when the index is requested.
func (c *Cached) GetCachedIndex(root string) (*Index, error) {
	var cs ChangeSlice

	// Load or create index.
	idx, path, err := c.getCachedIndex(root)
	if err != nil {
		// Generate new index.
		if idx, err = NewIndexFiles(root); err != nil {
			return nil, err
		}
	} else {
		// Update loaded index.
		cs = idx.Compare(root)
		idx.Apply(root, cs)
	}

	// If index changed or was generated, save it.
	if path == "" || len(cs) != 0 {
		if path == "" {
			if path, err = c.createTempPath(root); err != nil {
				return nil, err
			}
		}

		if err = SaveIndex(idx, path); err != nil {
			return nil, err
		}
	}

	return idx, nil
}

// HeadCachedIndex gets cached index or creates a new one and returns the number
// and the overall size of stored files.
func (c *Cached) HeadCachedIndex(root string) (count int, diskSize int64, err error) {
	idx, err := c.GetCachedIndex(root)
	if err != nil {
		return 0, 0, err
	}

	return idx.Count(-1), idx.DiskSize(-1), nil
}

// getCachedIndex looks up for index stored in one of temporary directories.
// If provided index is found, it will be loaded to memory and returned.
func (c *Cached) getCachedIndex(root string) (idx *Index, path string, err error) {
	name := hashSHA1(root)
	// Find index in temporary directories.
	for _, tempdir := range c.indexTempDirs(-1) {
		path = filepath.Join(tempdir, name)
		if _, err = os.Stat(path); err == nil {
			break
		}
	}

	if path == "" || err != nil {
		return nil, "", errors.New("index file not found")
	}

	// Read index content.
	f, err := os.Open(path)
	if err != nil {
		return nil, "", err
	}
	defer f.Close()

	idx = NewIndex()
	if err = json.NewDecoder(f).Decode(idx); err != nil {
		return nil, "", err
	}

	return idx, path, nil
}

// createTempPath creates a valid path to index file.
func (c *Cached) createTempPath(root string) (path string, err error) {
	if dirs := c.indexTempDirs(1); len(dirs) > 0 {
		path = dirs[0]
	} else {
		if path, err = ioutil.TempDir(c.tempDir(), tempIndexDirPrefix); err != nil {
			return "", err
		}
	}

	return filepath.Join(path, hashSHA1(root)), nil
}

// indexTempDirs reads all directory names that could be created by index cache.
func (c *Cached) indexTempDirs(n int) []string {
	d, err := os.Open(c.tempDir())
	if err != nil {
		return nil
	}
	defer d.Close()

	if n <= 0 {
		n = -1
	}

	var dirs []string
	for len(dirs) != n {
		// Limit the number of read directories. If no more directories are
		// left to read, err is io.EOF.
		names, err := d.Readdirnames(100)

		for i := range names {
			if strings.HasPrefix(names[i], tempIndexDirPrefix) {
				dirs = append(dirs, filepath.Join(c.tempDir(), names[i]))
			}
		}

		if err != nil {
			break
		}
	}

	return dirs
}

// tmpDir returns a file path to system's temporary directory.
func (c *Cached) tempDir() string {
	if c.TempDir == nil {
		return os.TempDir()
	}
	return c.TempDir()
}

// hashSHA1 converts a string to hex representation of its SHA-1 checksum.
func hashSHA1(val string) string {
	h := sha1.Sum([]byte(val))
	return hex.EncodeToString(h[:])
}

// SaveIndex atomically saves the provided index under a given path.
func SaveIndex(idx *Index, path string) (err error) {
	dir, name := filepath.Split(path)
	f, err := ioutil.TempFile(dir, name+"_")
	if err != nil {
		return err
	}

	if err := json.NewEncoder(f).Encode(idx); err == nil {
		err = f.Sync()
	}

	if cerr := f.Close(); cerr != nil && err == nil {
		err = cerr
	}

	if err == nil {
		err = os.Rename(f.Name(), path)
	}

	if err != nil {
		os.Remove(f.Name())
	}

	return err
}
