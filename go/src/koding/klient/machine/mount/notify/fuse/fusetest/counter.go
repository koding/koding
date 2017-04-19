package fusetest

import (
	"fmt"
	"os"
	"os/signal"
	"sort"
	"sync"
	"syscall"
	"time"

	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	"golang.org/x/net/context"
)

type measurement struct {
	mu sync.Mutex

	count       uint64
	averageTime float64
}

// Do calls `f`, counts its execution time and increases invocation number by 1.
func (m *measurement) Do(f func()) {
	start := time.Now()
	f()
	execution := float64(time.Since(start))

	m.mu.Lock()
	defer m.mu.Unlock()

	m.count++
	m.averageTime = (m.averageTime*float64(m.count-1) + execution) / float64(m.count)
}

// Status returns current measurement status.
func (m *measurement) Status() (uint64, time.Duration) {
	m.mu.Lock()
	defer m.mu.Unlock()

	return m.count, time.Duration(m.averageTime)
}

// CounterFS implements fuseutil.FileSystem. It counts function invocation
// times and the number of their calls.
type CounterFS struct {
	fuseutil.NotImplementedFileSystem
	watched fuseutil.FileSystem

	mu      sync.RWMutex
	methods map[string]*measurement
}

// NewCounterFS creates ad returns new CounterFS instance. It also starts
// listening for SIGTSTP signal and prints current status when the signal is
// trapped. Sending SIGTSTP twice will reset the counters.
func NewCounterFS(watched fuseutil.FileSystem) *CounterFS {
	cfs := &CounterFS{
		watched: watched,
		methods: make(map[string]*measurement),
	}

	go cfs.loop()

	return cfs
}

// StatFS is a part of fuseutil.FileSystem interface.
func (c *CounterFS) StatFS(ctx context.Context, op *fuseops.StatFSOp) (err error) {
	c.watch("StatFS", func(watched fuseutil.FileSystem) {
		err = watched.StatFS(ctx, op)
	})
	return
}

// LookUpInode is a part of fuseutil.FileSystem interface.
func (c *CounterFS) LookUpInode(ctx context.Context, op *fuseops.LookUpInodeOp) (err error) {
	c.watch("LookUpInode", func(watched fuseutil.FileSystem) {
		err = watched.LookUpInode(ctx, op)
	})
	return
}

// GetInodeAttributes is a part of fuseutil.FileSystem interface.
func (c *CounterFS) GetInodeAttributes(ctx context.Context, op *fuseops.GetInodeAttributesOp) (err error) {
	c.watch("GetInodeAttributes", func(watched fuseutil.FileSystem) {
		err = watched.GetInodeAttributes(ctx, op)
	})
	return
}

// SetInodeAttributes is a part of fuseutil.FileSystem interface.
func (c *CounterFS) SetInodeAttributes(ctx context.Context, op *fuseops.SetInodeAttributesOp) (err error) {
	c.watch("SetInodeAttributes", func(watched fuseutil.FileSystem) {
		err = watched.SetInodeAttributes(ctx, op)
	})
	return
}

// ForgetInode is a part of fuseutil.FileSystem interface.
func (c *CounterFS) ForgetInode(ctx context.Context, op *fuseops.ForgetInodeOp) (err error) {
	c.watch("ForgetInode", func(watched fuseutil.FileSystem) {
		err = watched.ForgetInode(ctx, op)
	})
	return
}

// MkDir is a part of fuseutil.FileSystem interface.
func (c *CounterFS) MkDir(ctx context.Context, op *fuseops.MkDirOp) (err error) {
	c.watch("MkDir", func(watched fuseutil.FileSystem) {
		err = watched.MkDir(ctx, op)
	})
	return
}

// MkNode is a part of fuseutil.FileSystem interface.
func (c *CounterFS) MkNode(ctx context.Context, op *fuseops.MkNodeOp) (err error) {
	c.watch("MkNode", func(watched fuseutil.FileSystem) {
		err = watched.MkNode(ctx, op)
	})
	return
}

// CreateFile is a part of fuseutil.FileSystem interface.
func (c *CounterFS) CreateFile(ctx context.Context, op *fuseops.CreateFileOp) (err error) {
	c.watch("CreateFile", func(watched fuseutil.FileSystem) {
		err = watched.CreateFile(ctx, op)
	})
	return
}

// CreateSymlink is a part of fuseutil.FileSystem interface.
func (c *CounterFS) CreateSymlink(ctx context.Context, op *fuseops.CreateSymlinkOp) (err error) {
	c.watch("CreateSymlink", func(watched fuseutil.FileSystem) {
		err = watched.CreateSymlink(ctx, op)
	})
	return
}

// Rename is a part of fuseutil.FileSystem interface.
func (c *CounterFS) Rename(ctx context.Context, op *fuseops.RenameOp) (err error) {
	c.watch("Rename", func(watched fuseutil.FileSystem) {
		err = watched.Rename(ctx, op)
	})
	return
}

// RmDir is a part of fuseutil.FileSystem interface.
func (c *CounterFS) RmDir(ctx context.Context, op *fuseops.RmDirOp) (err error) {
	c.watch("RmDir", func(watched fuseutil.FileSystem) {
		err = watched.RmDir(ctx, op)
	})
	return
}

// Unlink is a part of fuseutil.FileSystem interface.
func (c *CounterFS) Unlink(ctx context.Context, op *fuseops.UnlinkOp) (err error) {
	c.watch("Unlink", func(watched fuseutil.FileSystem) {
		err = watched.Unlink(ctx, op)
	})
	return
}

// OpenDir is a part of fuseutil.FileSystem interface.
func (c *CounterFS) OpenDir(ctx context.Context, op *fuseops.OpenDirOp) (err error) {
	c.watch("OpenDir", func(watched fuseutil.FileSystem) {
		err = watched.OpenDir(ctx, op)
	})
	return
}

// ReadDir is a part of fuseutil.FileSystem interface.
func (c *CounterFS) ReadDir(ctx context.Context, op *fuseops.ReadDirOp) (err error) {
	c.watch("ReadDir", func(watched fuseutil.FileSystem) {
		err = watched.ReadDir(ctx, op)
	})
	return
}

// ReleaseDirHandle is a part of fuseutil.FileSystem interface.
func (c *CounterFS) ReleaseDirHandle(ctx context.Context, op *fuseops.ReleaseDirHandleOp) (err error) {
	c.watch("ReleaseDirHandle", func(watched fuseutil.FileSystem) {
		err = watched.ReleaseDirHandle(ctx, op)
	})
	return
}

// OpenFile is a part of fuseutil.FileSystem interface.
func (c *CounterFS) OpenFile(ctx context.Context, op *fuseops.OpenFileOp) (err error) {
	c.watch("OpenFile", func(watched fuseutil.FileSystem) {
		err = watched.OpenFile(ctx, op)
	})
	return
}

// ReadFile is a part of fuseutil.FileSystem interface.
func (c *CounterFS) ReadFile(ctx context.Context, op *fuseops.ReadFileOp) (err error) {
	c.watch("ReadFile", func(watched fuseutil.FileSystem) {
		err = watched.ReadFile(ctx, op)
	})
	return
}

// WriteFile is a part of fuseutil.FileSystem interface.
func (c *CounterFS) WriteFile(ctx context.Context, op *fuseops.WriteFileOp) (err error) {
	c.watch("WriteFile", func(watched fuseutil.FileSystem) {
		err = watched.WriteFile(ctx, op)
	})
	return
}

// SyncFile is a part of fuseutil.FileSystem interface.
func (c *CounterFS) SyncFile(ctx context.Context, op *fuseops.SyncFileOp) (err error) {
	c.watch("SyncFile", func(watched fuseutil.FileSystem) {
		err = watched.SyncFile(ctx, op)
	})
	return
}

// FlushFile is a part of fuseutil.FileSystem interface.
func (c *CounterFS) FlushFile(ctx context.Context, op *fuseops.FlushFileOp) (err error) {
	c.watch("FlushFile", func(watched fuseutil.FileSystem) {
		err = watched.FlushFile(ctx, op)
	})
	return
}

// ReleaseFileHandle is a part of fuseutil.FileSystem interface.
func (c *CounterFS) ReleaseFileHandle(ctx context.Context, op *fuseops.ReleaseFileHandleOp) (err error) {
	c.watch("ReleaseFileHandle", func(watched fuseutil.FileSystem) {
		err = watched.ReleaseFileHandle(ctx, op)
	})
	return
}

// ReadSymlink is a part of fuseutil.FileSystem interface.
func (c *CounterFS) ReadSymlink(ctx context.Context, op *fuseops.ReadSymlinkOp) (err error) {
	c.watch("ReadSymlink", func(watched fuseutil.FileSystem) {
		err = watched.ReadSymlink(ctx, op)
	})
	return
}

// Destroy is a part of fuseutil.FileSystem interface.
func (c *CounterFS) Destroy() {
	c.watch("Destroy", func(watched fuseutil.FileSystem) {
		watched.Destroy()
	})
	return
}

func (c *CounterFS) watch(name string, f func(watched fuseutil.FileSystem)) {
	c.mu.RLock()
	ms := c.methods[name]
	if ms == nil {
		ms = &measurement{}
		c.methods[name] = ms
	}
	c.mu.RUnlock()

	ms.Do(func() {
		f(c.watched)
	})
}

func (c *CounterFS) loop() {
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGTSTP)

	for range ch {
		fmt.Fprintln(os.Stderr, "Printing method execution statuses:")

		c.mu.Lock()
		names := make([]string, 0, len(c.methods))
		for name := range c.methods {
			names = append(names, name)
		}

		sort.Strings(names)
		for _, name := range names {
			m := c.methods[name]

			count, averageTime := m.Status()
			fmt.Fprintf(os.Stderr, "%s\t\t%d\t%v", name, count, averageTime)
		}
		c.mu.Unlock()

		select {
		case <-ch:
			fmt.Fprintf(os.Stderr, "Reseting timers...")
			c.mu.Lock()
			c.methods = make(map[string]*measurement)
			c.mu.Unlock()
			fmt.Fprintln(os.Stderr, "OK")
		case <-time.After(500 * time.Millisecond):
			fmt.Fprintf(os.Stderr, "Method counter - Done")
		}
	}
}
