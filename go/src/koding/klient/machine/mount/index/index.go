package index

import (
	"crypto/sha1"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Entry represents a single file registered to index.
type Entry struct {
	Name  string      // The relative name of the file.
	CTime int64       // Metadata change time since EPOCH.
	MTime int64       // File data change time since EPOCH.
	Mode  os.FileMode // File mode and permission bits.
	Size  uint32      // Size of the file truncated to 32 bits.
	SHA1  []byte      // SHA-1 hash of file content.
}

// NewEntryFile creates new Entry from a file stored under path argument.
// Info is optional and, if given, should store LStat result on the given file.
func NewEntryFile(root, path string, info os.FileInfo) (e *Entry, err error) {
	if info == nil {
		if info, err = os.Lstat(path); err != nil {
			return nil, err
		}
	}

	// Get relative file name.
	name, err := filepath.Rel(root, path)
	if err != nil {
		return nil, err
	}

	// Compute file's SHA-1 sum.
	var sum []byte
	if !info.IsDir() {
		if sum, err = readSHA1(path); err != nil {
			return nil, err
		}
	}

	return &Entry{
		Name:  filepath.ToSlash(name),
		CTime: ctimeFromSys(info),
		MTime: info.ModTime().UnixNano(),
		Mode:  info.Mode(),
		Size:  safeTruncate(info.Size()),
		SHA1:  sum,
	}, nil
}

// safeTruncate converts signed integer to unsigned one returning 0 for negative
// values of provided argument.
func safeTruncate(n int64) uint32 {
	if n < 0 {
		return 0
	}

	return uint32(n)
}

// readSHA1 computes SHA-1 sum from a given file content.
func readSHA1(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	hash := sha1.New()
	if _, err := io.Copy(hash, file); err != nil {
		return nil, err
	}

	return hash.Sum(nil), nil
}

// ChangeMeta indicates what change has been done on a given file.
type ChangeMeta uint32

const (
	ChangeMetaUpdate ChangeMeta = 1 << iota // File was updated.
	ChangeMetaRemove                        // File was removed.
	ChangeMetaAdd                           // File was added.
)

// Change describes single file change.
type Change struct {
	Name      string     // The relative name of the file.
	Size      uint32     // Size of the file truncated to 32 bits.
	Meta      ChangeMeta // The type of operation made on file entry.
	CreatedAt int64      // Change creation time since EPOCH.
}

// ChangeSlice stores multiple changes.
type ChangeSlice []Change

func (cs ChangeSlice) Len() int           { return len(cs) }
func (cs ChangeSlice) Swap(i, j int)      { cs[i], cs[j] = cs[j], cs[i] }
func (cs ChangeSlice) Less(i, j int) bool { return cs[i].Name < cs[j].Name }

// Index stores a virtual working tree state. It recursively records objects in
// a given root path and allows to efficiently detect changes on it.
type Index struct {
	mu      sync.RWMutex
	entries map[string]*Entry
}

// NewIndex creates the empty index object.
func NewIndex() *Index {
	return &Index{
		entries: make(map[string]*Entry, 0),
	}
}

// NewIndexFiles walks the given file tree roted at root and records file
// states to resulting Index object.
func NewIndexFiles(root string) (*Index, error) {
	idx := NewIndex()

	// In order to get as much entries as we can we ignore errors.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		// Skip root path.
		if name, err := filepath.Rel(root, path); err != nil || name == "." {
			return nil
		}

		entry, err := NewEntryFile(root, path, info)
		if err != nil {
			return nil
		}

		idx.entries[entry.Name] = entry
		return nil
	}

	if err := filepath.Walk(root, walkFn); err != nil {
		return nil, err
	}

	return idx, nil
}

// Size returns the number of elements sored in index.
func (idx *Index) Size() int {
	idx.mu.RLock()
	idx.mu.RUnlock()

	return len(idx.entries)
}

// Compare rereads the given file tree roted at root and compares its entries
// to previous state of the index. All detected changes will be stored in
// returned Change slice.
func (idx *Index) Compare(root string) (cs ChangeSlice) {
	visited := make(map[string]struct{})

	// Walk over current root path and check it files.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		name, err := filepath.Rel(root, path)
		if err != nil || name == "." {
			return nil
		}
		name = filepath.ToSlash(name)

		idx.mu.RLock()
		entry, ok := idx.entries[name]
		idx.mu.RUnlock()

		// Not found in current index - file was added.
		if !ok {
			cs = append(cs, Change{
				Name:      name,
				Size:      safeTruncate(info.Size()),
				Meta:      ChangeMetaAdd,
				CreatedAt: time.Now().UnixNano(),
			})
			return nil
		}

		// Entry is read only-now. Check for changes.
		visited[name] = struct{}{}
		if entry.MTime != info.ModTime().UnixNano() ||
			entry.CTime != ctimeFromSys(info) ||
			entry.Size != uint32(info.Size()) {
			cs = append(cs, Change{
				Name:      name,
				Size:      safeTruncate(info.Size()),
				Meta:      ChangeMetaUpdate,
				CreatedAt: time.Now().UnixNano(),
			})
		}

		return nil
	}

	if err := filepath.Walk(root, walkFn); err != nil {
		return nil
	}

	// Check for removes.
	idx.mu.RLock()
	for name := range idx.entries {
		if _, ok := visited[name]; !ok {
			path := filepath.Join(root, filepath.FromSlash(name))
			if _, err := os.Lstat(path); os.IsNotExist(err) {
				cs = append(cs, Change{
					Name:      name,
					Meta:      ChangeMetaRemove,
					CreatedAt: time.Now().UnixNano(),
				})
			}
		}
	}
	idx.mu.RUnlock()

	return cs
}

// Apply modifies index according to provided changes. This function doesn't
// guarantee that changes from Compare function applied to the index will
// result in actual directory state.
func (idx *Index) Apply(root string, cs ChangeSlice) {
	for i := range cs {
		switch {
		case cs[i].Meta&(ChangeMetaUpdate|ChangeMetaAdd) != 0:
			idx.mu.RLock()
			entry, ok := idx.entries[cs[i].Name]
			idx.mu.RUnlock()

			// Entry was updated/added after the event was created.
			if ok && entry.MTime > cs[i].CreatedAt {
				continue
			}
			fallthrough
		case cs[i].Meta&ChangeMetaRemove != 0:
			path := filepath.Join(root, filepath.FromSlash(cs[i].Name))
			info, err := os.Lstat(path)
			if os.IsNotExist(err) {
				idx.mu.Lock()
				delete(idx.entries, cs[i].Name)
				idx.mu.Unlock()
				continue
			}

			entry, err := NewEntryFile(root, path, info)
			if err != nil {
				continue
			}

			idx.mu.Lock()
			idx.entries[entry.Name] = entry
			idx.mu.Unlock()
		}
	}
}
