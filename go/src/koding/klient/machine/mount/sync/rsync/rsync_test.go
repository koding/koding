package rsync_test

import (
	"os/exec"
	"strings"
	"testing"

	"koding/klient/machine/index"
	"koding/klient/machine/index/indextest"
	"koding/klient/machine/mount/mounttest"
	"koding/klient/machine/mount/sync/rsync"
	"koding/klient/machine/mount/sync/synctest"
	"time"
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

	cm := []index.ChangeMeta{
		index.ChangeMetaLocal,
		index.ChangeMetaRemote,
	}

	for _, dir := range cm {
		for name, test := range tests {
			name = strings.Replace(dir.String(), "-", "", -1) + "_" + name
			dir, test := dir, test // Capture range variables.
			t.Run(name, func(t *testing.T) {
				t.Parallel()

				// Generate two identical file trees.
				rootA, rootB, clean, err := indextest.GenerateMirrorTrees(filetree)
				if err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}
				defer clean()

				// Make change on first file tree.
				if err := test(rootA); err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}

				// Synchronize underlying file-system.
				indextest.Sync()

				s := rsync.NewRsync()
				ctx, cancel, err := synctest.SyncLocal(rootA, rootB, dir, s)
				if err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}
				defer cancel()

				if err := mounttest.WaitForContextClose(ctx, time.Second); err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}

				// Syncer should make two trees identical as they were.
				cs, err := indextest.ComparePath(rootA, rootB)
				if err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}

				if l := len(cs); l != 0 {
					t.Fatalf("want changes length = 0; got %d: %v", l, cs)
				}
			})
		}
	}
}
