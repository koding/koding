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
		t: idx.t.DataClone(),
	}
}

// Tree returns index tree.
func (idx *Index) Tree() *node.Tree {
	return idx.t
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
		rootBranch: {}, // Skip root file.
	}

	idx.t.DoPath(branch, node.WalkPath(func(name string, n *node.Node) {
		if n.IsShadowed() {
			return
		}

		nameOS := filepath.FromSlash(name)
		nodePath := filepath.Join(rootBranch, nameOS)
		visited[nodePath] = struct{}{}

		info, err := os.Lstat(nodePath)
		if os.IsNotExist(err) {
			// File exists in remote but not in local.
			n.PromiseVirtual()
			cs = append(cs, NewChange(
				filepath.ToSlash(filepath.Join(branch, nameOS)),
				PriorityLow,
				ChangeMetaAdd|ChangeMetaRemote,
			))
			return
		} else if err != nil {
			return
		}

		mode, size, mtime := n.Entry.File.Mode, n.Entry.File.Size, n.Entry.File.MTime
		// File exists in both remote and local. We compare entry mtime with
		// file mtime and atime. Sometimes synced files may have their mtimes
		// set to source atime. That's why this is necessary.
		if (mtime == info.ModTime().UTC().UnixNano() || mtime == atime(info)) &&
			size == info.Size() &&
			mode == info.Mode() {
			// Files are identical. Allow different ctimes.
			n.UnsetPromises()
			return
		}

		// Merge will not report directory updates because this means that file
		// inside directory was added/removed and this file should be reported.
		// Howewer we want to detect permission changes in all files.
		if mode.IsDir() && mode == info.Mode() {
			n.UnsetPromises()
			return
		}

		// Files differ. However the local file is not virtual.
		n.PromiseUpdate()
		cs = append(cs, NewChange(
			filepath.ToSlash(filepath.Join(branch, nameOS)),
			PriorityMedium,
			ChangeMetaUpdate,
		))
	}))

	// Walk over current root path and check its files.
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
		name = filepath.ToSlash(name)

		// Add files to tree.
		idx.t.DoPath(name, node.Insert(node.NewEntryFileInfo(info)))
		cs = append(cs, NewChange(name, PriorityLow, ChangeMetaAdd))

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
	idx.t.DoPath(c.Path(), func(n *node.Node) bool {
		if os.IsNotExist(err) {
			// File doesn't exist. Return false to remove it from tree.
			return false
		} else if err != nil {
			// Nothing much we can do here. Return true to not remove the node.
			return true
		}

		if n.IsShadowed() {
			// File exists on disk but not in tree. Set entry and return true.
			n.Entry = node.NewEntryFileInfo(info)
		} else {
			n.Entry.MergeIn(node.NewEntryFileInfo(info))
			n.UnsetPromises()
		}

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
	if err := json.NewEncoder(w).Encode(idx.t); err != nil {
		w.Close()
		return nil, err
	}
	w.Close()

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
	idx.t.DoPath("", node.WalkPath(func(nodePath string, n *node.Node) {
		m[nodePath] = n.Entry
	}))

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

// atime gets file's access time in UNIX Nano format.
func atime(fi os.FileInfo) int64 {
	return times.Get(fi).AccessTime().UnixNano()
}
