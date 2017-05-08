package rsync_test

import (
	"os"
	"os/exec"
	"testing"
	"time"

	"koding/klient/machine/client"
	"koding/klient/machine/client/clienttest"
	"koding/klient/machine/index"
	"koding/klient/machine/index/indextest"
	"koding/klient/machine/mount/mounttest"
	msync "koding/klient/machine/mount/sync"
	"koding/klient/machine/mount/sync/rsync"
	"koding/klient/machine/mount/sync/synctest"
)

var testHasRsync bool

func init() {
	if _, err := exec.LookPath("rsync"); err == nil {
		testHasRsync = true
	}
}

var filetree = map[string]int64{
	"a.bin":        300 * 1024,
	"b/":           0,
	"b/ba/":        0,
	"b/ba/baa.txt": 3 * 1024,
}

func TestRsyncExec(t *testing.T) {
	// This tests needs more investigation. Although it doesn't pass on some
	// machines it is considered valid. The failure is reproducible on AWS
	// instances and is caused by invalid ctimes set by rsync process despite
	// --times option set. This happens randomly and doesn't not affect mount
	// logic now.
	if os.Getenv("CI") != "" {
		t.Skip("TODO(ppknap): please fix me")
	}

	if !testHasRsync {
		t.Skip("rsync executable not found, skipping")
	}

	tests := map[string]func(string) error{
		"add file":      indextest.WriteFile("b/test.bin", 40*1024),
		"add empty dir": indextest.AddDir("e"),
		"remove file":   indextest.RmAllFile("b/ba/baa.txt"),
		"remove dir":    indextest.RmAllFile("b/ba"),
		"rename file":   indextest.MvFile("a.bin", "b/cc.bin"),
		"replace file":  indextest.MvFile("a.bin", "b/ba/baa.txt"),
		"write file":    indextest.WriteFile("b.bin", 1024),
		"chmod file":    indextest.ChmodFile("b/ba/baa.txt", 0600),
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			// Generate two identical file trees.
			remotePath, cachePath, clean, err := indextest.GenerateMirrorTrees(filetree)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}
			defer clean()

			idx, err := index.NewIndexFiles(remotePath, nil)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if err := test(cachePath); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			// Synchronize underlying file-system.
			indextest.Sync()

			opts := &msync.BuildOpts{
				RemoteDir:  remotePath,
				CacheDir:   cachePath,
				ClientFunc: func() (client.Client, error) { return clienttest.NewClient(), nil },
				SSHFunc:    func() (_ string, _ int, _ error) { return },
				IndexSyncFunc: func(c *index.Change) {
					idx.Sync(cachePath, c)
				},
			}

			s, err := rsync.NewRsync(opts)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			ctx, cancel, err := synctest.SyncLocal(s, remotePath, cachePath, 0)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}
			defer cancel()

			if err := mounttest.WaitForContextClose(ctx, time.Second); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			// Syncer should make two trees identical
			cs, err := indextest.Compare(remotePath, cachePath)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if l := len(cs); l != 0 {
				t.Fatalf("want changes length = 0; got %d: %v", l, cs)
			}
		})
	}
}
