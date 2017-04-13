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
	"text/tabwriter"

	"koding/klient/machine/index/node"

	"github.com/djherbis/times"
)

// Version stores current version of index.
const Version = 1

// Index stores a virtual working tree state. It recursively records objects in
// a given root path and allows to efficiently detect changes on it.
type Index struct {
	t *node.Tree
}

var (
	_ json.Marshaler   = (*Index)(nil)
	_ json.Unmarshaler = (*Index)(nil)
)

// NewIndex creates the empty index object.
func NewIndex() *Index {
	return &Index{
		t: node.NewTree(),
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
		// Get relative file name.
		name, err := filepath.Rel(root, f.path)
		if err != nil {
			continue
		}

		// Set root path to zero value.
		if name == "." {
			name = ""
		}

		idx.t.DoPath(name, node.Insert(node.NewEntryFileInfo(f.info)))
	}
}

// Clone returns a deep copy of called index.
func (idx *Index) Clone() *Index {
	return &Index{
		t: idx.t.DataClone(), // TODO: virtual also?
	}
}

// PromiseAdd adds a node under the given path marked as newly added.
//
// If mode is non-zero, the node's mode is overwritten with the value.
// If the node already exists, it'd be only marked with EntryPromiseAdd flag.
// If the node is already marked as newly added, the method is a no-op.
func (idx *Index) PromiseAdd(path string, entry *node.Entry) {
	idx.t.DoPath(path, node.Insert(entry))
}

// PromiseDel marks a node under the given path as deleted.
//
// If the node does not exist or is already marked as deleted, the
// method is no-op.
//
// If node is non-nil, then it's used instead of looking it up
// by the given path.
func (idx *Index) PromiseDel(path string) {
	idx.t.DoPath(path, (*node.Node).PromiseDel)
}

// PromiseUnlink marks a node under the given path as unlinked.
//
// If the node does not exist or is already marked as unlinked,
// the method is a no-op.
//
// If node is non-nil, then it's used instead of looking it up
// by the given path.
func (idx *Index) PromiseUnlink(path string) {
	idx.t.DoPath(path, (*node.Node).PromiseUnlink)
}

// Count returns the number of entries stored in index. Only items which size is
// below provided value are counted. If provided argument is negative, this
// function will return the number of all entries. It does not count files
// marked as virtual or deleted.
func (idx *Index) Count(maxsize int64) (n int) {
	idx.t.DoPath("", node.Count(&n)) // TODO: maxsize
	return
}

// CountAll behaves like Count but it counts It does count files marked as
// virtual or deleted.
func (idx *Index) CountAll(maxsize int64) (n int) {
	idx.t.DoPath("", node.CountAll(&n)) // TODO: maxsize
	return
}

// DiskSize tells how much disk space would be used by entries stored in index.
// Only items which size is below provided value are counted. If provided
// argument is negative, this function will count disk size of all items. It
// does not count size of files marked as virtual or deleted.
func (idx *Index) DiskSize(maxsize int64) (n int64) {
	idx.t.DoPath("", node.DiskSize(&n))
	return
}

// DiskSizeAll behaves like DiskSize but it includes files marked as virtual or
// deleted.
func (idx *Index) DiskSizeAll(maxsize int64) (n int64) {
	idx.t.DoPath("", node.DiskSize(&n))
	return
}

// Merge calls MergeBranch on all nodes pointed by root path.
func (idx *Index) Merge(root string) ChangeSlice {
	return idx.MergeBranch(root, "")
}

// MergeBranch rereads the given file tree rooted at root and merges its
// entries with index state rooted at branch node. The called index is treated
// as remote part. Scanned directory is considered local part. The following
// rules apply:
//
//  1. If file exists in both remote and local, its fileinfos will be compared
//     with remote entry and if they differs, ChangeMetaUpdate will be created
//     with the direction specified by the result of ctime and mtime comparison.
//
//  2. If file exists in remote but not in local, the entry will have
//     EntryPromiseVirtual property, and ChangeMetaAdd from remote to local
//     will be created.
//
//  3. If file exists in local but not in remote, the entry will be created in
//     remote with EntryPromiseAdd property, and ChangeMetaAdd from local to
//     remote will be produced.
//
// All detected changes will be stored in returned Change slice.
// If branch is empty, the comparison is made against root of the index.
func (idx *Index) MergeBranch(root, branch string) (cs ChangeSlice) {
	rootBranch := filepath.Join(root, branch)
	visited := map[string]struct{}{
		rootBranch: {}, // Skip root.
	}

	// if !ok {
	//	goto skipBranch
	// }

	idx.t.DoPath(branch, func(nd *node.Node) bool {
		if nd.Entry == nil {
			return false
		}

		nameOS := filepath.FromSlash(nd.Name)
		visited[filepath.Join(rootBranch, nameOS)] = struct{}{}

		info, err := os.Lstat(filepath.Join(rootBranch, nameOS))
		if os.IsNotExist(err) {
			// File exists in remote but not in local.
			nd.Entry.Virtual.Promise.Swap(node.EntryPromiseVirtual, 0)
			cs = append(cs, NewChange(
				filepath.ToSlash(filepath.Join(branch, nameOS)),
				PriorityLow,
				ChangeMetaAdd|ChangeMetaRemote,
			))
			return true
		}

		// There is nothing we can do with this error.
		if err != nil {
			return false
		}

		mode, mtime, size := nd.Entry.File.Mode, nd.Entry.File.MTime, nd.Entry.File.Size
		// File exists in both remote and local. We compare entry mtime with
		// file mtime and atime. Sometimes synced files may have their mtimes
		// set to source atime. That's why this is necessary.
		if (mtime == info.ModTime().UnixNano() || mtime == atime(info)) && size == info.Size() && mode == info.Mode() {
			// Files are identical. Allow different ctimes.
			nd.Entry.Virtual.Promise.Swap(0, node.EntryPromiseVirtual)
			return true
		}

		// Merge will not report directory updates because this means that file
		// inside directory was added/removed and this file should be reported.
		// Howewer we want to detect permission changes in all files.
		if mode.IsDir() && mode == info.Mode() {
			nd.Entry.Virtual.Promise.Swap(0, node.EntryPromiseVirtual)
			return true
		}

		// Files differ. However the local file is not virtual.
		nd.Entry.Virtual.Promise.Swap(node.EntryPromiseUpdate, node.EntryPromiseVirtual)
		cs = append(cs, NewChange(
			filepath.ToSlash(filepath.Join(branch, nameOS)),
			PriorityMedium,
			ChangeMetaUpdate,
		))

		return true
	})

	// Walk over current root path and check it files.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		if _, ok := visited[path]; ok {
			return nil
		}

		// File exists in local but not in remote.
		name, err := filepath.Rel(root, path)
		if err != nil {
			return nil
		}

		cs = append(cs, NewChange(
			filepath.ToSlash(name),
			PriorityLow,
			ChangeMetaAdd,
		))

		// TODO: store all entries, find common root and walk only once
		idx.t.DoPath(filepath.ToSlash(name), node.Insert(node.NewEntryFileInfo(info)))

		return nil
	}

	if err := filepath.Walk(rootBranch, walkFn); err != nil {
		return nil
	}

	// Put sortest paths to the end.
	sort.Sort(sort.Reverse(cs))
	return cs
}

// Sync modifies index according to provided change path. It checks the file
// on the underlying file system and updates its corresponding index entry.
// This function invalidates all promises set in change entry.
func (idx *Index) Sync(root string, c *Change) {
	if c == nil {
		return
	}

	info, err := os.Lstat(filepath.Join(root, filepath.FromSlash(c.Path())))
	if os.IsNotExist(err) {
		idx.t.DoPath(c.Path(), node.Delete)
		return
	} else if err != nil {
		// Nothing much we can do here.
		return
	}

	// Get file node pointed by the change.
	idx.t.DoPath(c.Path(), func(nd *node.Node) bool {
		if nd.Entry == nil {
			nd.Entry = node.NewEntryFileInfo(info)
		}

		// Update entry and unset all promises.
		nd.Entry.File.CTime = ctime(info)
		nd.Entry.File.MTime = info.ModTime().UTC().UnixNano()
		nd.Entry.File.Size = info.Size()
		nd.Entry.File.Mode = info.Mode()
		nd.Entry.Virtual.Promise = 0

		return true
	})

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
	var b bytes.Buffer
	w := gzip.NewWriter(&b)

	err := json.NewEncoder(w).Encode(idx.t)
	w.Close()

	if err != nil {
		return nil, err
	}

	return []byte(`"` + base64.StdEncoding.EncodeToString(b.Bytes()) + `"`), nil
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private index fields.
func (idx *Index) UnmarshalJSON(data []byte) error {
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

	if err = json.NewDecoder(r).Decode(&idx.t); err != nil {
		return err
	}

	return nil
}

// DebugString dumps content of the index as a string, suitable for debugging.
func (idx *Index) DebugString() string {
	m := make(map[string]*node.Entry)
	fn := func(nd *node.Node) bool {
		m[nd.Name] = nd.Entry
		return true
	}

	idx.t.DoPath("", fn)

	paths := make([]string, 0, len(m))
	for path := range m {
		paths = append(paths, path)
	}
	sort.Strings(paths)

	var buf bytes.Buffer
	tw := tabwriter.NewWriter(&buf, 0, 0, 1, ' ', 0)
	for i, path := range paths {
		fmt.Fprintf(tw, "%5d %s\t%v\n", i+1, path, m[path])
	}
	tw.Flush()

	return buf.String()
}

// ctime gets file's change time in UNIX Nano format.
func ctime(fi os.FileInfo) int64 {
	if tspec := times.Get(fi); tspec.HasChangeTime() {
		return tspec.ChangeTime().UnixNano()
	}

	return 0
}

// atime gets file's access time in UNIX Nano format.
func atime(fi os.FileInfo) int64 {
	return times.Get(fi).AccessTime().UnixNano()
}
