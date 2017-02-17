package index

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"sort"
	"sync"
	"sync/atomic"

	"github.com/djherbis/times"
)

// Version stores current version of index.
const Version = 1

// Entry group describes values of an Entry.Meta field.
const (
	EntryPromiseAdd = 1 << iota
	EntryPromiseUpdate
	EntryPromiseDel
	EntryPromiseUnlink
)

// Entry represents a single file registered to index.
type Entry struct {
	// File disk state fields.
	CTime int64       `json:"c"` // Metadata change time since EPOCH.
	MTime int64       `json:"m"` // File data change time since EPOCH.
	Size  int64       `json:"s"` // Size of the file.
	Mode  os.FileMode `json:"o"` // File mode and permission bits.

	// File dynamic state fields.
	inode uint64 // Inode ID of a mounted file.
	ref   int32  // Reference count of file handlers.
	meta  int32  // Metadata of files's memory state.
}

// The following methods are convenience helpers for a lock-free
// access of Entry's fields.
func (e *Entry) GetInode() uint64      { return atomic.LoadUint64(&e.inode) }
func (e *Entry) SetInode(inode uint64) { atomic.StoreUint64(&e.inode, inode) }
func (e *Entry) GetSize() int64        { return atomic.LoadInt64(&e.Size) }
func (e *Entry) SetSize(n int64)       { atomic.StoreInt64(&e.Size, n) }
func (e *Entry) IncRef() int32         { return atomic.AddInt32(&e.ref, 1) }
func (e *Entry) DecRef() int32         { return atomic.AddInt32(&e.ref, -1) }
func (e *Entry) Has(meta int32) bool   { return atomic.LoadInt32(&e.meta)&meta == meta }

// SwapMeta flips the value of a Meta field, setting the set
// bits and unsetting the unset ones.
func (e *Entry) SwapMeta(set, unset int32) int32 {
	for {
		older := atomic.LoadInt32(&e.meta)
		updated := (older | set) &^ unset

		if atomic.CompareAndSwapInt32(&e.meta, older, updated) {
			return updated
		}
	}
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

	return filepath.ToSlash(name), &Entry{
		CTime: ctime(info),
		MTime: info.ModTime().UnixNano(),
		Mode:  info.Mode(),
		Size:  info.Size(),
	}, nil
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

// PromiseAdd adds a node under the given path marked as newly added.
//
// If mode is non-zero, the node's mode is overwritten with the value.
// If the node already exists, it'd be only marked with EntryPromiseAdd flag.
// If the node is already marked as newly added, the method is a no-op.
func (idx *Index) PromiseAdd(path string, entry *Entry) {
	idx.mu.Lock()
	idx.root.PromiseAdd(path, entry)
	idx.mu.Unlock()
}

// PromiseDel marks a node under the given path as deleted.
//
// If the node does not exist or is already marked as deleted, the
// method is no-op.
//
// If node is non-nil, then it's used instead of looking it up
// by the given path.
func (idx *Index) PromiseDel(path string, node *Node) {
	idx.mu.Lock()
	idx.root.PromiseDel(path, node)
	idx.mu.Unlock()
}

// PromiseUnlink marks a node under the given path as unlinked.
//
// If the node does not exist or is already marked as unlinked,
// the method is a no-op.
//
// If node is non-nil, then it's used instead of looking it up
// by the given path.
func (idx *Index) PromiseUnlink(path string, node *Node) {
	idx.mu.Lock()
	idx.root.PromiseUnlink(path, node)
	idx.mu.Unlock()
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

// Lookup looks up a node by the given name.
func (idx *Index) Lookup(name string) (*Node, bool) {
	idx.mu.RLock()
	defer idx.mu.RUnlock()

	return idx.root.Lookup(name)
}

// Compare rereads the given file tree roted at root and compares its entries
// to previous state of the index. All detected changes will be stored in
// returned Change slice.
func (idx *Index) Compare(root string) ChangeSlice {
	return idx.CompareBranch("", root)
}

// CompareBranch rereads the given file tree roted at root and compares its entries
// with index state roted at branch node.
//
// All detected changes will be stored in returned Change slice.
// If branch is empty, the comparison is made against root of the index.
func (idx *Index) CompareBranch(branch, root string) (cs ChangeSlice) {
	idx.mu.RLock()
	rt, ok := idx.root.Lookup(branch)
	idx.mu.RUnlock()

	if !ok {
		rt = newNode()
	}

	visited := make(map[string]struct{})

	rootBranch := filepath.Join(root, branch)

	// Walk over current root path and check it files.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		name, err := filepath.Rel(rootBranch, path)
		if err != nil || name == "." {
			return nil
		}

		name = filepath.ToSlash(name)

		idx.mu.RLock()
		nd, ok := rt.Lookup(name)
		idx.mu.RUnlock()

		name = filepath.Join(branch, name)

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

	if err := filepath.Walk(rootBranch, walkFn); err != nil {
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

	return ChangeMetaHuge
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
			nd, ok := idx.root.Lookup(cs[i].Path())
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
			path := filepath.Join(root, filepath.FromSlash(cs[i].Path()))
			info, err := os.Lstat(path)
			if os.IsNotExist(err) {
				idx.mu.Lock()
				idx.root.Del(cs[i].Path())
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

	if err = json.NewDecoder(r).Decode(&idx.root); err != nil {
		return err
	}

	// BUG(rjeczalik): Something overwrites the root entry
	// with a zero value elsewhere. Fix me.
	idx.root.Entry = newEntry()
	idx.root.Entry.Mode |= os.ModeDir

	return nil

}

// DebugString dumps content of the index as a string, suitable for debugging.
func (idx *Index) DebugString() string {
	m := make(map[string]*Entry)

	fn := func(path string, entry *Entry) {
		m[path] = entry
	}

	idx.mu.RLock()
	idx.root.forEach(fn, true)
	idx.mu.RUnlock()

	paths := make([]string, 0, len(m))

	for path := range m {
		paths = append(paths, path)
	}

	sort.Strings(paths)

	var buf bytes.Buffer

	for _, path := range paths {
		fmt.Fprintf(&buf, "%s => %#v\n", path, m[path])
	}

	return buf.String()
}
