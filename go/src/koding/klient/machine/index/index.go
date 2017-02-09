package index

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"hash/crc32"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"sync"

	"github.com/djherbis/times"
)

// Version stores current version of index.
const Version = 1

// Entry represents a single file registered to index.
type Entry struct {
	CTime int64       `json:"c"` // Metadata change time since EPOCH.
	MTime int64       `json:"m"` // File data change time since EPOCH.
	Mode  os.FileMode `json:"o"` // File mode and permission bits.
	Size  int64       `json:"s"` // Size of the file.
	Hash  []byte      `json:"h"` // Hash of file content.
	Aux   uint64      `json:"-"` // Auxiliary data, fuse uses it to store fuseops.InodeID.
}

// NewEntryFile creates new Entry from a file stored under path argument.
// Info is optional and, if given, should store LStat result on the given file.
func NewEntryFile(root, path string, info os.FileInfo) (name string, e *Entry, err error) {
	if info == nil {
		if info, err = os.Lstat(path); err != nil {
			return "", nil, err
		}
	}

	// Get relative file name.
	name, err = filepath.Rel(root, path)
	if err != nil {
		return "", nil, err
	}

	// Compute file's hash sum.
	var sum []byte
	if !info.IsDir() {
		if sum, err = readCRC32(path); err != nil {
			return "", nil, err
		}
	}

	return filepath.ToSlash(name), &Entry{
		CTime: ctime(info),
		MTime: info.ModTime().UnixNano(),
		Mode:  info.Mode(),
		Size:  info.Size(),
		Hash:  sum,
	}, nil
}

var copyBufPool = sync.Pool{
	New: func() interface{} {
		b := make([]byte, 64*1024)
		return &b
	},
}

// readCRC32 computes CRC-32 checksum of a given file content.
func readCRC32(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	hash := crc32.NewIEEE()

	bufp := copyBufPool.Get().(*[]byte)
	defer copyBufPool.Put(bufp)

	if _, err := io.CopyBuffer(hash, file, *bufp); err != nil {
		return nil, err
	}

	return hash.Sum(nil), nil
}

// Index stores a virtual working tree state. It recursively records objects in
// a given root path and allows to efficiently detect changes on it.
type Index struct {
	mu   sync.RWMutex
	root *Node
}

var (
	_ json.Marshaler   = (*Index)(nil)
	_ json.Unmarshaler = (*Index)(nil)
)

// NewIndex creates the empty index object.
func NewIndex() *Index {
	return &Index{
		root: newNode(),
	}
}

type fileDesc struct {
	path string      // relative path to the file.
	info os.FileInfo // file LStat result.
}

// NewIndexFiles walks the given file tree roted at root and records file
// states to resulting Index object.
func NewIndexFiles(root string) (*Index, error) {
	idx := NewIndex()

	// Start worker pool.
	var wg sync.WaitGroup
	fC := make(chan *fileDesc)
	for i := 0; i < 2*runtime.NumCPU(); i++ {
		wg.Add(1)
		go idx.addEntryWorker(root, &wg, fC)
	}
	defer func() {
		close(fC)
		wg.Wait()
	}()

	// In order to get as much entries as we can we ignore errors.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		// Skip root path.
		if name, err := filepath.Rel(root, path); err != nil || name == "." {
			return nil
		}

		fC <- &fileDesc{path: path, info: info}
		return nil
	}

	if err := filepath.Walk(root, walkFn); err != nil {
		return nil, err
	}

	return idx, nil
}

// addEntryWorker asynchronously adds new entry to index. Errors are ignored.
func (idx *Index) addEntryWorker(root string, wg *sync.WaitGroup, fC <-chan *fileDesc) {
	defer wg.Done()

	for f := range fC {
		name, entry, err := NewEntryFile(root, f.path, f.info)
		if err != nil {
			continue
		}

		idx.mu.Lock()
		idx.root.Add(name, entry)
		idx.mu.Unlock()
	}
}

// Count returns the number of entries stored in index. Only items which size is
// below provided value are counted. If provided argument is negative, this
// function will return the number of all entries.
func (idx *Index) Count(maxsize int64) int {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	return idx.root.Count(maxsize)
}

// DiskSize tells how much disk space would be used by entries stored in index.
// Only items which size is below provided value are counted. If provided
// argument is negative, this function will count disk size of all items.
func (idx *Index) DiskSize(maxsize int64) int64 {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	return idx.root.DiskSize(maxsize)
}

func (idx *Index) Lookup(name string) (*Node, bool) {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	return idx.root.Lookup(name)
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
		nd, ok := idx.root.Lookup(name)
		idx.mu.RUnlock()

		// Not found in current index - file was added.
		if !ok {
			cs = append(cs, NewChange(name, ChangeMetaAdd|markLargeMeta(info.Size())))
			return nil
		}

		// Entry is read only-now. Check for changes.
		visited[name] = struct{}{}
		if nd.Entry.MTime != info.ModTime().UnixNano() ||
			nd.Entry.CTime != ctime(info) ||
			nd.Entry.Size != info.Size() {
			cs = append(cs, NewChange(name, ChangeMetaUpdate|markLargeMeta(info.Size())))
		}

		return nil
	}

	if err := filepath.Walk(root, walkFn); err != nil {
		return nil
	}

	// Check for removes.
	idx.mu.RLock()
	idx.root.ForEach(func(name string, entry *Entry) {
		if _, ok := visited[name]; !ok {
			path := filepath.Join(root, filepath.FromSlash(name))

			if _, err := os.Lstat(path); os.IsNotExist(err) {
				cs = append(cs, NewChange(name, ChangeMetaRemove|markLargeMeta(entry.Size)))
			}
		}
	})
	idx.mu.RUnlock()

	return cs
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
	// Start worker pool.
	var wg sync.WaitGroup
	fC := make(chan *fileDesc)
	for i := 0; i < naturalMin(2*runtime.NumCPU(), len(cs)); i++ {
		wg.Add(1)
		go idx.addEntryWorker(root, &wg, fC)
	}

	for i := range cs {
		switch {
		case cs[i].Meta()&(ChangeMetaUpdate|ChangeMetaAdd) != 0:
			// Check if the event is still valid or if it was replaced by newer
			// change.
			idx.mu.RLock()
			nd, ok := idx.root.Lookup(cs[i].Name())
			idx.mu.RUnlock()

			// Entry was updated/added after the event was created.
			if ok && nd.Entry.MTime > cs[i].CreatedAtUnixNano() {
				continue
			}
			fallthrough
		case cs[i].Meta()&ChangeMetaRemove != 0:
			// Check if the file still exists, since it could be removed before
			// Apply was called. If the file exists, create new entry from it
			// and replace its value inside index map.
			path := filepath.Join(root, filepath.FromSlash(cs[i].Name()))
			info, err := os.Lstat(path)
			if os.IsNotExist(err) {
				idx.mu.Lock()
				idx.root.Del(cs[i].Name())
				idx.mu.Unlock()
				continue
			}

			fC <- &fileDesc{path: path, info: info}
		}
	}

	close(fC)
	wg.Wait()
}

// naturalMin returns the minimal value of provided arguments but not less than
// one.
func naturalMin(a, b int) (n int) {
	if n = b; a < b {
		n = a
	}

	if n < 1 {
		return 1
	}

	return n
}

// MarshalJSON satisfies json.Marshaler interface. It safely marshals index
// private data to JSON format.
func (idx *Index) MarshalJSON() ([]byte, error) {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	var b bytes.Buffer
	w := gzip.NewWriter(&b)
	if err := json.NewEncoder(w).Encode(idx.root); err != nil {
		w.Close()
		return nil, err
	}
	w.Close()

	return []byte(`"` + base64.StdEncoding.EncodeToString(b.Bytes()) + `"`), nil
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private index fields.
func (idx *Index) UnmarshalJSON(data []byte) error {
	idx.mu.Lock()
	defer idx.mu.Unlock()

	dst := make([]byte, base64.StdEncoding.DecodedLen(len(data)-2))
	n, err := base64.StdEncoding.Decode(dst, data[1:len(data)-1])
	if err != nil {
		return err
	}

	r, err := gzip.NewReader(bytes.NewReader(dst[:n]))
	if err != nil {
		return err
	}
	defer r.Close()

	return json.NewDecoder(r).Decode(&idx.root)
}
