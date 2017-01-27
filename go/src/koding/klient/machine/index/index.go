package index

import (
	"crypto/sha1"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"time"

	"github.com/djherbis/times"
)

// Version stores current version of index.
const Version = 1

// Entry represents a single file registered to index.
type Entry struct {
	Name  string      `json:"name"`  // The relative name of the file.
	CTime int64       `json:"ctime"` // Metadata change time since EPOCH.
	MTime int64       `json:"mtime"` // File data change time since EPOCH.
	Mode  os.FileMode `json:"mode"`  // File mode and permission bits.
	Size  int64       `json:"size"`  // Size of the file.
	SHA1  []byte      `json:"sha1"`  // SHA-1 hash of file content.
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
		CTime: ctime(info),
		MTime: info.ModTime().UnixNano(),
		Mode:  info.Mode(),
		Size:  info.Size(),
		SHA1:  sum,
	}, nil
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

	ChangeMetaLarge ChangeMeta = 1 << (8 + iota) // File size is above 4GB.
)

// Change describes single file change.
type Change struct {
	Name      string     `json:"name"`      // The relative name of the file.
	Size      uint32     `json:"size"`      // Size of the file truncated to 32 bits.
	Meta      ChangeMeta `json:"meta"`      // The type of operation made on file entry.
	CreatedAt int64      `json:"createdAt"` // Change creation time since EPOCH.
}

// ChangeSlice stores multiple changes.
type ChangeSlice []Change

func (cs ChangeSlice) Len() int           { return len(cs) }
func (cs ChangeSlice) Swap(i, j int)      { cs[i], cs[j] = cs[j], cs[i] }
func (cs ChangeSlice) Less(i, j int) bool { return cs[i].Name < cs[j].Name }

// Index stores a virtual working tree state. It recursively records objects in
// a given root path and allows to efficiently detect changes on it.
type Index struct {
	limitC chan struct{}

	mu      sync.RWMutex
	entries map[string]*Entry
}

var (
	_ json.Marshaler   = (*Index)(nil)
	_ json.Unmarshaler = (*Index)(nil)
)

// NewIndex creates the empty index object.
func NewIndex() *Index {
	return &Index{
		limitC:  make(chan struct{}, 2*runtime.NumCPU()),
		entries: make(map[string]*Entry, 0),
	}
}

// NewIndexFiles walks the given file tree roted at root and records file
// states to resulting Index object.
func NewIndexFiles(root string) (*Index, error) {
	idx := NewIndex()

	// In order to get as much entries as we can we ignore errors.
	var wg sync.WaitGroup
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		// Skip root path.
		if name, err := filepath.Rel(root, path); err != nil || name == "." {
			return nil
		}

		wg.Add(1)
		idx.addEntry(&wg, root, path, info)
		return nil
	}

	if err := filepath.Walk(root, walkFn); err != nil {
		return nil, err
	}

	wg.Wait()
	return idx, nil
}

// addEntry asynchronously adds new entry to index. This function has limits
// to a number of started go-routines. Errors are ignored.
func (idx *Index) addEntry(wg *sync.WaitGroup, root, path string, info os.FileInfo) {
	idx.limitC <- struct{}{}

	go func() {
		defer func() {
			<-idx.limitC
			wg.Done()
		}()

		entry, err := NewEntryFile(root, path, info)
		if err != nil {
			return
		}

		idx.mu.Lock()
		idx.entries[entry.Name] = entry
		idx.mu.Unlock()
	}()
}

// Count returns the number of entries stored in index. Only items which size is
// below provided value are counted. If provided argument is negative, this
// function will return the number of all entries.
func (idx *Index) Count(maxsize int64) (count int) {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	if maxsize < 0 {
		return len(idx.entries)
	} else if maxsize == 0 {
		return 0
	}

	for _, entry := range idx.entries {
		if entry != nil && entry.Size <= maxsize {
			count++
		}
	}

	return count
}

// DiskSize tells how much disk space would be used by entries stored in index.
// Only items which size is below provided value are counted. If provided
// argument is negative, this function will count disk size of all items.
func (idx *Index) DiskSize(maxsize int64) (size int64) {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	if maxsize == 0 {
		return 0
	}

	for _, entry := range idx.entries {
		if entry != nil && (maxsize < 0 || entry.Size <= maxsize) {
			size += entry.Size
		}
	}

	return size
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
				Meta:      ChangeMetaAdd | markLargeMeta(info.Size()),
				CreatedAt: time.Now().UnixNano(),
			})
			return nil
		}

		// Entry is read only-now. Check for changes.
		visited[name] = struct{}{}
		if entry.MTime != info.ModTime().UnixNano() ||
			entry.CTime != ctime(info) ||
			entry.Size != info.Size() {
			cs = append(cs, Change{
				Name:      name,
				Size:      safeTruncate(info.Size()),
				Meta:      ChangeMetaUpdate | markLargeMeta(info.Size()),
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
					Meta:      ChangeMetaRemove | markLargeMeta(idx.entries[name].Size),
					CreatedAt: time.Now().UnixNano(),
				})
			}
		}
	}
	idx.mu.RUnlock()

	return cs
}

// safeTruncate converts signed integer to unsigned one returning 0 for negative
// values of provided argument.
func safeTruncate(n int64) uint32 {
	if n < 0 {
		return 0
	}

	return uint32(n)
}

// markLargeMeta adds large file flag for files which size is over 4GiB.
func markLargeMeta(n int64) ChangeMeta {
	if n < 0 || (n>>32) == 0 {
		return 0
	}

	return ChangeMetaLarge
}

// ctime gets file's change time in UNIX Nano format.
func ctime(fi os.FileInfo) int64 {
	if tspec := times.Get(fi); tspec.HasChangeTime() {
		return tspec.ChangeTime().UnixNano()
	}

	return 0
}

// Apply modifies index according to provided changes. This function doesn't
// guarantee that changes from Compare function applied to the index will
// result in actual directory state.
func (idx *Index) Apply(root string, cs ChangeSlice) {
	var wg sync.WaitGroup

	for i := range cs {
		switch {
		case cs[i].Meta&(ChangeMetaUpdate|ChangeMetaAdd) != 0:
			// Check if the event is still valid or if it was replaced by newer
			// change.
			idx.mu.RLock()
			entry, ok := idx.entries[cs[i].Name]
			idx.mu.RUnlock()

			// Entry was updated/added after the event was created.
			if ok && entry.MTime > cs[i].CreatedAt {
				continue
			}
			fallthrough
		case cs[i].Meta&ChangeMetaRemove != 0:
			// Check if the file still exists, since it could be removed before
			// Apply was called. If the file exists, create new entry from it
			// and replace its value inside index map.
			path := filepath.Join(root, filepath.FromSlash(cs[i].Name))
			info, err := os.Lstat(path)
			if os.IsNotExist(err) {
				idx.mu.Lock()
				delete(idx.entries, cs[i].Name)
				idx.mu.Unlock()
				continue
			}

			wg.Add(1)
			idx.addEntry(&wg, root, path, info)
		}
	}

	wg.Wait()
}

// MarshalJSON satisfies json.Marshaler interface. It safely marshals index
// private data to JSON format.
func (idx *Index) MarshalJSON() ([]byte, error) {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	return json.Marshal(idx.entries)
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private index fields.
func (idx *Index) UnmarshalJSON(data []byte) error {
	idx.mu.Lock()
	defer idx.mu.Unlock()

	return json.Unmarshal(data, &idx.entries)
}
