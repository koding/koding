package index

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
