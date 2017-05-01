package mount

import (
	"encoding/json"
	"errors"
	"fmt"
	"path/filepath"
	"sync"

	uuid "github.com/satori/go.uuid"
)

var (
	// ErrMountNotFound indicates that provided mount does not exist.
	ErrMountNotFound = errors.New("mount not found")
)

// ID is a unique identifier of the mount.
type ID string

// MakeID makes a new unique mount identifier.
func MakeID() ID {
	return ID(uuid.NewV4().String())
}

// IDFromString parses provided token and converts it to mount ID.
func IDFromString(tok string) (ID, error) {
	id, err := uuid.FromString(tok)
	if err != nil {
		return "", err
	}

	if id.Version() != 4 {
		return "", errors.New("invalid mount ID format")
	}

	return ID(id.String()), nil
}

// IDSlice stores multiple mount IDs.
type IDSlice []ID

func (ids IDSlice) Len() int           { return len(ids) }
func (ids IDSlice) Swap(i, j int)      { ids[i], ids[j] = ids[j], ids[i] }
func (ids IDSlice) Less(i, j int) bool { return ids[i] < ids[j] }

// StringSlice converts mount ID slice to string slice.
func (ids IDSlice) StringSlice() (res []string) {
	for _, id := range ids {
		res = append(res, string(id))
	}

	return res
}

// Mount stores information about a single local to remote machine mount.
type Mount struct {
	Path       string `json:"path"`       // Mount point.
	RemotePath string `json:"remotePath"` // Remote directory path.
}

// String return a string form of stored mount.
func (m Mount) String() string {
	remotePath, path := "<unknown>", "<unknown>"

	if m.RemotePath != "" {
		remotePath = m.RemotePath
	}
	if m.Path != "" {
		path = m.Path
	}

	return remotePath + " -> " + path
}

// MountBook stores and manages multiple mounts. Local machine can have multiple
// mounts to single remote device. This structure is meant to store all of them.
type MountBook struct {
	mu     sync.RWMutex
	mounts map[ID]Mount
}

var (
	_ json.Marshaler   = (*MountBook)(nil)
	_ json.Unmarshaler = (*MountBook)(nil)
)

// NewMountBook creates an empty mount book.
func NewMountBook() *MountBook {
	return &MountBook{
		mounts: make(map[ID]Mount),
	}
}

// Add adds given mount to mount book.
func (mb *MountBook) Add(id ID, mount Mount) error {
	mb.mu.Lock()
	defer mb.mu.Unlock()

	if m, ok := mb.mounts[id]; ok {
		return fmt.Errorf("mount with provided id already exists: %s", m)
	}

	mb.mounts[id] = mount
	return nil
}

// Remove removes the mount with provided ID from mount book.
func (mb *MountBook) Remove(id ID) {
	mb.mu.Lock()
	defer mb.mu.Unlock()

	delete(mb.mounts, id)
}

// Path returns mount ID which mount's local path matches provided argument.
// This function returns ErrMountNotFound if neither of stored mounts uses the
// given path. Provided path must be in its absolute and cleaned representation.
func (mb *MountBook) Path(path string) (ID, error) {
	if !filepath.IsAbs(path) {
		return "", fmt.Errorf("path %q is not absolute", path)
	}

	mb.mu.RLock()
	defer mb.mu.RUnlock()

	for id, mount := range mb.mounts {
		if mount.Path == path {
			return id, nil
		}
	}

	return "", ErrMountNotFound
}

// RemotePath returns mount IDs which RemotePath field matches provided
// argument. Although it is not recommended, multiple mounts can mount the same
// remote directory to different local paths. This function returns
// ErrMountNotFound if neither of stored mounts uses the given path. Provided
// path must be in its absolute and cleaned representation.
func (mb *MountBook) RemotePath(path string) (ids IDSlice, err error) {
	if !filepath.IsAbs(path) {
		return nil, fmt.Errorf("path %q is not absolute", path)
	}

	mb.mu.RLock()
	defer mb.mu.RUnlock()

	for id, mount := range mb.mounts {
		if mount.RemotePath == path {
			ids = append(ids, id)
		}
	}

	if len(ids) != 0 {
		return ids, nil
	}

	return nil, ErrMountNotFound
}

// All returns a copy of all mounts stored in mount book.
func (mb *MountBook) All() map[ID]Mount {
	mb.mu.RLock()
	defer mb.mu.RUnlock()

	cp := make(map[ID]Mount, len(mb.mounts))
	for id, mount := range mb.mounts {
		cp[id] = mount
	}

	return cp
}

// MarshalJSON satisfies json.Marshaler interface. It safely marshals mount book
// private data to JSON format.
func (mb *MountBook) MarshalJSON() ([]byte, error) {
	mb.mu.RLock()
	defer mb.mu.RUnlock()

	return json.Marshal(mb.mounts)
}

// UnmarshalJSON satisfies json.Unmarshaler interface. It is used to unmarshal
// data into private mount book fields.
func (mb *MountBook) UnmarshalJSON(data []byte) error {
	mb.mu.RLock()
	defer mb.mu.RUnlock()

	return json.Unmarshal(data, &mb.mounts)
}
