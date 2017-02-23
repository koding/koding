package rsync_test

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"os/exec"
	"reflect"
	"strings"
	"testing"
	"time"

	"koding/klient/machine"
	"koding/klient/machine/index"
	"koding/klient/machine/index/indextest"
	"koding/klient/machine/mount"
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

func dumpArgs(w io.Writer) func(_ context.Context, args ...string) *exec.Cmd {
	return func(_ context.Context, args ...string) *exec.Cmd {
		cargs := append([]string{"-test.run=TestHelperProcess", "--"}, args...)

		cmd := exec.Command(os.Args[0], cargs...)
		cmd.Env = []string{"GO_WANT_HELPER_PROCESS=1"}
		cmd.Stdout = w
		return cmd
	}
}

func TestRsyncArgs(t *testing.T) {
	tests := map[string]struct {
		Meta     index.ChangeMeta
		Expected []string
	}{
		"file added locally": {
			Meta:     index.ChangeMetaAdd | index.ChangeMetaLocal,
			Expected: []string{"-e", "ssh -i /home/pk -oStrictHostKeyChecking=no", "--include='/b.txt'", "--exclude='*'", "-zlptgoDd", "/c/a/", "user@127.0.0.1:/r/a/"},
		},
		"file updated locally": {
			Meta:     index.ChangeMetaUpdate | index.ChangeMetaLocal,
			Expected: []string{"-e", "ssh -i /home/pk -oStrictHostKeyChecking=no", "--include='/b.txt'", "--exclude='*'", "-zlptgoDd", "/c/a/", "user@127.0.0.1:/r/a/"},
		},
		"file removed locally": {
			Meta:     index.ChangeMetaRemove | index.ChangeMetaLocal,
			Expected: []string{"-e", "ssh -i /home/pk -oStrictHostKeyChecking=no", "--delete", "--include='/b.txt'", "--exclude='*'", "-zlptgoDd", "/c/a/", "user@127.0.0.1:/r/a/"},
		},
		"file added remotely": {
			Meta:     index.ChangeMetaAdd | index.ChangeMetaRemote,
			Expected: []string{"-e", "ssh -i /home/pk -oStrictHostKeyChecking=no", "--include='/b.txt'", "--exclude='*'", "-zlptgoDd", "user@127.0.0.1:/r/a/", "/c/a/"},
		},
		"file updated remotely": {
			Meta:     index.ChangeMetaUpdate | index.ChangeMetaRemote,
			Expected: []string{"-e", "ssh -i /home/pk -oStrictHostKeyChecking=no", "--include='/b.txt'", "--exclude='*'", "-zlptgoDd", "user@127.0.0.1:/r/a/", "/c/a/"},
		},
		"file removed remotely": {
			Meta:     index.ChangeMetaRemove | index.ChangeMetaRemote,
			Expected: []string{"-e", "ssh -i /home/pk -oStrictHostKeyChecking=no", "--delete", "--include='/b.txt'", "--exclude='*'", "-zlptgoDd", "user@127.0.0.1:/r/a/", "/c/a/"},
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			var buf bytes.Buffer

			dynAddr := func(string) (machine.Addr, error) {
				return machine.Addr{
					Network: "ip",
					Value:   "127.0.0.1",
				}, nil
			}

			opts := &msync.BuildOpts{
				Mount:          mount.Mount{RemotePath: "/r"},
				CacheDir:       "/c",
				PrivateKeyPath: "/home/pk",
				Username:       "user",
				AddrFunc:       dynAddr,
				IndexSyncFunc:  func(*index.Change) {},
			}

			s := rsync.NewRsync(opts)
			s.Cmd = dumpArgs(&buf)

			change := index.NewChange("a/b.txt", test.Meta)
			if err := synctest.ExecChange(s, change, time.Second); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			got := strings.Split(buf.String(), "\n")
			if !reflect.DeepEqual(got, test.Expected) {
				t.Fatalf("want exec args = %v; got %v", test.Expected, got)
			}
		})
	}
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

			idx, err := index.NewIndexFiles(remotePath)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			if err := test(cachePath); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			// Synchronize underlying file-system.
			indextest.Sync()

			opts := &msync.BuildOpts{
				Mount:    mount.Mount{RemotePath: remotePath},
				CacheDir: cachePath,
				AddrFunc: func(string) (_ machine.Addr, _ error) { return },
				IndexSyncFunc: func(c *index.Change) {
					idx.Sync(cachePath, c)
				},
			}

			s := rsync.NewRsync(opts)
			ctx, cancel, err := synctest.SyncLocal(s, remotePath, cachePath, 0)
			if err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}
			defer cancel()

			if err := mounttest.WaitForContextClose(ctx, time.Second); err != nil {
				t.Fatalf("want err = nil; got %v", err)
			}

			// Syncer should make two trees identical as they were.
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

// TestHelperProcess is not a real test. It is used as a helper process and
// prints each given command line argument in a separate line.
func TestHelperProcess(t *testing.T) {
	if os.Getenv("GO_WANT_HELPER_PROCESS") != "1" {
		return
	}
	defer os.Exit(0)

	args := os.Args
	for len(args) > 0 {
		if args[0] == "--" {
			args = args[1:]
			break
		}
		args = args[1:]
	}

	fmt.Fprintf(os.Stdout, strings.Join(args, "\n"))
}
