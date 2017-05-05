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
	"time"

	"koding/klient/machine/index/filter"
)

// TempIndexDirPrefix defines the prefix of temporary index file created by
// Cached structure.
const TempIndexDirPrefix = "koding_index_"

// DefaultFilter defines a default filter used to process index caching.
var DefaultFilter filter.Filter = filter.MultiFilter{
	filter.OsSkip(filter.DirectorySkip(".Trash"), "darwin"),                                                                   // OSX trash directory.
	filter.OsSkip(filter.DirectorySkip(".Trashes"), "darwin"),                                                                 // OSX trash directory.
	filter.OsSkip(filter.DirectorySkip(".fseventsd"), "darwin"),                                                               // FSEvents notify.
	filter.NewWithError(filter.PathSuffixSkip(".git/index.lock"), "git repository on remote is in use"),                       // git index lock file.
	filter.NewWithError(filter.PathSuffixSkip(".git/refs/stash.lock"), "git repository on remote is in use"),                  // git stash lock file.
	filter.NewWithError(filter.PathSuffixSkip(".git/HEAD.lock"), "git repository on remote is in use"),                        // git HEAD lock.
	filter.NewWithError(filter.PathSuffixSkip(".git/ORIG_HEAD.lock"), "git repository on remote is in use"),                   // git ORIG_HEAD lock.
	filter.NewWithError(filter.NewRegexSkip(`\.git/refs/heads/[^\s]+\.lock$`), "git repository on remote is in use"),          // git branch lock.
	filter.NewWithError(filter.NewRegexSkip(`\.git/index\.stash\.\d+\.lock$`), "git repository on remote is in use"),          // git stash ref. lock.
	filter.NewWithError(filter.NewRegexSkip(`\.git/objects/pack/tmp_pack_[^/]+`), "git repository on remote is being cloned"), // temporary git files.
}

// Cached allows to cache and reuse previously created index.
type Cached struct {
	// Rescan is a time duration after which the cached file will be rescanned.
	// Eg. If cached file is modified at time point A, cache will not try
	// to update changes when called between A+`Rescan`.
	Rescan time.Duration

	// Function used to retrieve temporary directory. If nil, os.TempDir will be
	// used.
	TempDir func() string

	// Filter is used to skip unwanted files from storing them in index or to
	// fail the entire process if there are temporary files that can break the
	// consistency of file tree. DefaultFilter is used when this field is nil.
	Filter filter.Filter
}

// GetCachedIndex returns index that describes the current directory state. This
// function stores the resulting index in temporary file in order to not
// recompute it each time when the index is requested.
func (c *Cached) GetCachedIndex(root string) (*Index, error) {
	var cs ChangeSlice
	if c.Filter == nil {
		c.Filter = DefaultFilter
	}

	// Load or create index.
	idx, path, createdAt, err := c.getCachedIndex(root)
	if err != nil {
		// Generate new index.
		if idx, err = NewIndexFiles(root, c.Filter); err != nil {
			return nil, err
		}
	} else if createdAt.IsZero() || time.Since(createdAt) > c.Rescan {
		// Update loaded index.
		if cs, err = idx.Merge(root, c.Filter); err != nil {
			return nil, err
		}

		for _, c := range cs {
			idx.Sync(root, c)
		}
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

	return idx.Tree().Count(), idx.Tree().DiskSize(), nil
}

// getCachedIndex looks up for index stored in one of temporary directories.
// If provided index is found, it will be loaded to memory and returned.
func (c *Cached) getCachedIndex(root string) (idx *Index, path string, createdAt time.Time, err error) {
	name := hashSHA1(root)
	// Find index in temporary directories.
	for _, tempdir := range c.indexTempDirs(-1) {
		path = filepath.Join(tempdir, name)
		if _, err = os.Stat(path); err == nil {
			break
		}
	}

	if path == "" || err != nil {
		return nil, "", time.Time{}, errors.New("index file not found")
	}

	// Read index content.
	f, err := os.Open(path)
	if err != nil {
		return nil, "", time.Time{}, err
	}
	defer f.Close()

	idx = NewIndex()
	if err = json.NewDecoder(f).Decode(idx); err != nil {
		return nil, "", time.Time{}, err
	}

	// Get file mtime.
	if info, err := os.Stat(path); err == nil {
		createdAt = info.ModTime()
	}

	return idx, path, createdAt, nil
}

// createTempPath creates a valid path to index file.
func (c *Cached) createTempPath(root string) (path string, err error) {
	if dirs := c.indexTempDirs(1); len(dirs) > 0 {
		path = dirs[0]
	} else {
		if path, err = ioutil.TempDir(c.tempDir(), TempIndexDirPrefix); err != nil {
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
			if strings.HasPrefix(names[i], TempIndexDirPrefix) {
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
	f, err := ioutil.TempFile(filepath.Split(path))
	if err != nil {
		return err
	}

	defer func() {
		if err != nil {
			os.Remove(f.Name())
		}
	}()

	if err = json.NewEncoder(f).Encode(idx); err != nil {
		return err
	}

	if err = f.Sync(); err != nil {
		return err
	}

	if err = f.Close(); err != nil {
		return err
	}

	return os.Rename(f.Name(), path)
}
