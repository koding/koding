package client

import (
	"context"

	"koding/klient/machine/index"
)

// Cached
type Cached struct{}

var _ Client = (*Cached)(nil)

// NewCached creates a new Cached client instance.
func NewCached() *Cached {
	return &Cached{}
}

// CurrentUser
func (c *Cached) CurrentUser() (user string, err error) {
	return
}

// SSHAddKeys
func (c *Cached) SSHAddKeys(username string, keys ...string) (err error) {
	return
}

// MountHeadIndex
func (c *Cached) MountHeadIndex(path string) (absPath string, count int, diskSize int64, err error) {
	return
}

// MountGetIndex
func (c *Cached) MountGetIndex(path string) (idx *index.Index, err error) {
	return
}

// DiskBlocks gets basic information about volume pointed by provided path.
func (c *Cached) DiskBlocks(string) (size, total, free, used uint64, err error) {
	return
}

// Context
func (c *Cached) Context() context.Context {
	return nil
}
