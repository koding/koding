package prefetch

import "koding/klient/machine/index"

// All prefetcher always downloads all files stored in index.
type All struct{}

// Available always returns true since All prefetcher doesn't need any
// additional third-party tools.
func (All) Available() bool { return true }

// Weight returns All prefetcher weight.
func (All) Weight() int { return 0 }

// Scan gets size and number of prefetched files.
func (All) Scan(idx *index.Index) (suffix string, count, diskSize int64, err error) {
	count, diskSize = int64(idx.Tree().Count()), idx.Tree().DiskSize()
	return
}

// PostRun is a no-op for All prefetcher.
func (All) PostRun(_ string) error { return nil }
