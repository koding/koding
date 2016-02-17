package store

import (
	"bytes"
	"fmt"
	"io"

	"github.com/docker/notary/tuf/data"
	"github.com/docker/notary/tuf/utils"
)

// NewMemoryStore returns a MetadataStore that operates entirely in memory.
// Very useful for testing
func NewMemoryStore(meta map[string][]byte, files map[string][]byte) RemoteStore {
	if meta == nil {
		meta = make(map[string][]byte)
	}
	if files == nil {
		files = make(map[string][]byte)
	}
	return &memoryStore{
		meta:  meta,
		files: files,
		keys:  make(map[string][]data.PrivateKey),
	}
}

type memoryStore struct {
	meta  map[string][]byte
	files map[string][]byte
	keys  map[string][]data.PrivateKey
}

func (m *memoryStore) GetMeta(name string, size int64) ([]byte, error) {
	d, ok := m.meta[name]
	if ok {
		if int64(len(d)) < size {
			return d, nil
		}
		return d[:size], nil
	}
	return nil, ErrMetaNotFound{Resource: name}
}

func (m *memoryStore) SetMeta(name string, meta []byte) error {
	m.meta[name] = meta
	return nil
}

func (m *memoryStore) SetMultiMeta(metas map[string][]byte) error {
	for role, blob := range metas {
		m.SetMeta(role, blob)
	}
	return nil
}

// RemoveMeta removes the metadata for a single role - if the metadata doesn't
// exist, no error is returned
func (m *memoryStore) RemoveMeta(name string) error {
	delete(m.meta, name)
	return nil
}

func (m *memoryStore) GetTarget(path string) (io.ReadCloser, error) {
	return &utils.NoopCloser{Reader: bytes.NewReader(m.files[path])}, nil
}

func (m *memoryStore) WalkStagedTargets(paths []string, targetsFn targetsWalkFunc) error {
	if len(paths) == 0 {
		for path, dat := range m.files {
			meta, err := data.NewFileMeta(bytes.NewReader(dat), "sha256")
			if err != nil {
				return err
			}
			if err = targetsFn(path, meta); err != nil {
				return err
			}
		}
		return nil
	}

	for _, path := range paths {
		dat, ok := m.files[path]
		if !ok {
			return ErrMetaNotFound{Resource: path}
		}
		meta, err := data.NewFileMeta(bytes.NewReader(dat), "sha256")
		if err != nil {
			return err
		}
		if err = targetsFn(path, meta); err != nil {
			return err
		}
	}
	return nil
}

func (m *memoryStore) Commit(map[string][]byte, bool, map[string]data.Hashes) error {
	return nil
}

func (m *memoryStore) GetKey(role string) ([]byte, error) {
	return nil, fmt.Errorf("GetKey is not implemented for the memoryStore")
}

// Clear this existing memory store by setting this store as new empty one
func (m *memoryStore) RemoveAll() error {
	m.meta = make(map[string][]byte)
	m.files = make(map[string][]byte)
	m.keys = make(map[string][]data.PrivateKey)
	return nil
}
