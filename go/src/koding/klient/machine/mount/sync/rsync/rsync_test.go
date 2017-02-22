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
	"koding/klient/machine/mount/mounttest"
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
			Expected: []string{"a", "b", "c"},
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

			s := rsync.NewRsync("/remote", "/local", dynAddr, func(*index.Change) {})
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
	t.Skip("TODO")

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

				idx, err := index.NewIndexFiles(rootA)
				if err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}
				syncFunc := func(c *index.Change) {
					idx.Sync(rootA, c)
				}

				// Make change on first file tree.
				if err := test(rootA); err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}

				// Synchronize underlying file-system.
				indextest.Sync()

				dynAddr := func(string) (a machine.Addr, err error) { return }
				s := rsync.NewRsync(rootA, rootB, dynAddr, syncFunc)
				ctx, cancel, err := synctest.SyncLocal(s, rootA, rootB, dir)
				if err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}
				defer cancel()

				if err := mounttest.WaitForContextClose(ctx, time.Second); err != nil {
					t.Fatalf("want err = nil; got %v", err)
				}

				// Syncer should make two trees identical as they were.
				cs, err := indextest.Compare(rootA, rootB)
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
