package index

import (
	"crypto/sha1"
	"io"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type Entry struct {
	Name  string      // The relative name of the file.
	CTime int64       // Metadata change time since EPOCH.
	MTime int64       // File data change time since EPOCH.
	Mode  os.FileMode // File mode and permission bits.
	Size  uint32      // Size of the file truncated to 32 bits.
	SHA1  []byte      // SHA-1 hash of file content.
}

func NewEntryFile(root, path string, info os.FileInfo) (*Entry, error) {
	sum, err := readSHA1(path)
	if err != nil {
		return nil, err
	}

	name, err := filepath.Rel(root, path)
	if err != nil {
		return nil, err
	}

	log.Printf("Name: %s: % x", path, sum)
	return &Entry{
		Name:  filepath.ToSlash(name),
		CTime: ctimeFromSys(info),
		MTime: info.ModTime().UnixNano(),
		Mode:  info.Mode(),
		Size:  safeTruncate(info.Size()),
		SHA1:  sum,
	}, nil
}

func safeTruncate(n int64) uint32 {
	if n < 0 {
		return 0
	}

	return uint32(n)
}

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

type Change uint32

const (
	ChangeUpdate Change = 1 << iota // File was updated.
	ChangeRemove                    // File was removed.
	ChangeAdded                     // File was added.
)

type ChangeInfo struct {
	Name      string // The relative name of the file.
	Size      uint32 // Size of the file truncated to 32 bits.
	Type      Change // The type of operation made on file entry.
	CreatedAt int64  // Change creation time since EPOCH.
}

type Index struct {
	mu      sync.RWMutex
	entries map[string]*Entry
}

func NewIndex() *Index {
	return &Index{
		entries: make(map[string]*Entry, 0),
	}
}

func NewIndexFiles(root string) (*Index, error) {
	idx := NewIndex()

	// In order to get as much entries as we can we ignore errors.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
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

func (idx *Index) Compare(root string) (cis []ChangeInfo) {
	visited := make(map[string]struct{})

	// Walk over current root path and check it files.
	walkFn := func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		name, err := filepath.Rel(root, path)
		if err != nil {
			return nil
		}
		name = filepath.ToSlash(name)

		idx.mu.RLock()
		entry, ok := idx.entries[name]
		idx.mu.RUnlock()

		// Not found in current index - file was added.
		if !ok {
			cis = append(cis, ChangeInfo{
				Name:      name,
				Size:      safeTruncate(info.Size()),
				Type:      ChangeAdded,
				CreatedAt: time.Now().UnixNano(),
			})
			return nil
		}

		// Entry is read only-now. Check for changes.
		visited[name] = struct{}{}
		if entry.MTime != info.ModTime().UnixNano() ||
			entry.CTime != ctimeFromSys(info) ||
			entry.Size != uint32(info.Size()) {
			cis = append(cis, ChangeInfo{
				Name:      name,
				Size:      safeTruncate(info.Size()),
				Type:      ChangeUpdate,
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
				cis = append(cis, ChangeInfo{
					Name:      name,
					Type:      ChangeRemove,
					CreatedAt: time.Now().UnixNano(),
				})
			}
		}
	}
	idx.mu.RUnlock()

	return cis
}

func (idx *Index) Apply(root string, cis []ChangeInfo) {
	for i := range cis {
		switch cis[i].Type {
		case ChangeUpdate, ChangeAdded:
			idx.mu.RLock()
			entry, ok := idx.entries[cis[i].Name]
			idx.mu.RUnlock()

			// Entry was updated/added after the event was created.
			if ok && entry.MTime > cis[i].CreatedAt {
				continue
			}
			fallthrough
		case ChangeRemove:
			path := filepath.Join(root, filepath.FromSlash(cis[i].Name))
			info, err := os.Lstat(path)
			if os.IsNotExist(err) {
				idx.mu.Lock()
				delete(idx.entries, cis[i].Name)
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
