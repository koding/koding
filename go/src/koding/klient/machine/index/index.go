package index

import (
	"bytes"
	"compress/gzip"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"text/tabwriter"

	"koding/klient/machine/index/filter"
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
func NewIndexFiles(root string, f filter.Filter) (*Index, error) {
	idx := NewIndex()

	if f == nil {
		f = filter.NeverSkip{}
	}

	// In order to get as much entries as we can we ignore errors.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		if e := f.Check(filepath.ToSlash(path)); e == filter.SkipPath {
			return nil
		} else if e != nil {
			return e
		}

		// Get relative file name.
		name, err := filepath.Rel(root, path)
		if err != nil {
			return nil
		}

		// Set root path to zero value.
		if name == "." {
			name = ""
		}

		idx.t.DoPath(filepath.ToSlash(name), node.Insert(node.NewEntryFileInfo(info)))
		return nil
	}

	if err := filepath.Walk(root, walkFn); err != nil {
		return nil, err
	}

	return idx, nil
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
func (idx *Index) Merge(root string, f filter.Filter) (ChangeSlice, error) {
	return idx.MergeBranch(root, "", f)
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
func (idx *Index) MergeBranch(root, branch string, f filter.Filter) (cs ChangeSlice, err error) {
	rootBranch := filepath.Join(root, branch)
	visited := map[string]struct{}{
		rootBranch: {}, // Skip root file.
	}

	if f == nil {
		f = filter.NeverSkip{}
	}

	idx.t.DoPath(branch, node.WalkPath(func(name string, g node.Guard, n *node.Node) {
		if n.IsShadowed() || n.Entry.File.Mode == 0 {
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

		// Set entry inode but not for root inode.
		if n.Entry.File.Inode != node.RootInodeID {
			g.ChangeInode(n, node.Inode(info))
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

		if e := f.Check(filepath.ToSlash(path)); e == filter.SkipPath {
			return nil
		} else if e != nil {
			return e
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
		return nil, err
	}

	// Put sortest paths to the end.
	sort.Sort(sort.Reverse(cs))
	return cs, nil
}

// Sync modifies index according to provided change path. It checks the file
// on the underlying file system and updates its corresponding index entry.
// This function invalidates all promises set in change entry.
func (idx *Index) Sync(root string, c *Change) {
	if c == nil {
		return
	}

	info, err := os.Lstat(filepath.Join(root, filepath.FromSlash(c.Path())))
	idx.t.DoPath(c.Path(), func(g node.Guard, n *node.Node) bool {
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

		// Inodes may have changed. Update tree.
		if n.Entry.File.Inode != node.RootInodeID {
			g.ChangeInode(n, node.Inode(info))
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
		// Try converting to old nodes.
		rn, err := gzip.NewReader(bytes.NewReader(dst[:n]))
		if err != nil {
			return err
		}
		defer rn.Close()

		var root Node
		if err = json.NewDecoder(rn).Decode(&root); err == nil {
			idx.t = root.ToTree()
		} else {
			return err
		}
	}

	return nil
}

// Debug contains information about internal state of single index node.
type Debug struct {
	Path string `json:"path"`
	Info string `json:"info"`
}

// Debug returns the debug information about index.
func (idx *Index) Debug() (dbg []Debug) {
	m := make(map[string]*node.Entry)
	idx.t.DoPath("", node.WalkPath(func(nodePath string, _ node.Guard, n *node.Node) {
		m[nodePath] = n.Entry
	}))

	paths := make([]string, 0, len(m))
	for path := range m {
		paths = append(paths, path)
	}
	sort.Strings(paths)

	for _, path := range paths {
		dbg = append(dbg, Debug{
			Path: path,
			Info: m[path].String(),
		})
	}

	return dbg
}

// DebugString dumps content of the index as a string, suitable for debugging.
func (idx *Index) DebugString() string {
	var buf bytes.Buffer
	tw := tabwriter.NewWriter(&buf, 0, 0, 1, ' ', 0)
	for i, d := range idx.Debug() {
		fmt.Fprintf(tw, "%5d %s\t%s\n", i+1, d.Path, d.Info)
	}
	tw.Flush()

	return buf.String()
}

// Diagnose runs full diagnostic on current index tree state.
//
// TODO: Run diagnostic on underlying cache.
func (idx *Index) Diagnose(_ string) []string {
	return idx.t.Diagnose()
}

// atime gets file's access time in UNIX Nano format.
func atime(fi os.FileInfo) int64 {
	return times.Get(fi).AccessTime().UnixNano()
}
