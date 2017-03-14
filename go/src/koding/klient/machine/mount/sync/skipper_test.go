package sync_test

import (
	"context"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"koding/klient/machine/index"
	msync "koding/klient/machine/mount/sync"
)

func TestIsSkip(t *testing.T) {
	ctx := context.Background()
	tests := map[string]struct {
		Ev     *msync.Event
		Sk     msync.Skipper
		IsSkip bool
	}{
		"directory itself": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".Trash", 0)),
			Sk:     msync.DirectorySkip(".Trash"),
			IsSkip: true,
		},
		"file inside directory": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".Trash/file.txt", 0)),
			Sk:     msync.DirectorySkip(".Trash"),
			IsSkip: true,
		},
		"similar prefix": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".Trasher/file.txt", 0)),
			Sk:     msync.DirectorySkip(".Trash"),
			IsSkip: false,
		},
		"in the middle": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("aa/.Trasher/file.txt", 0)),
			Sk:     msync.DirectorySkip(".Trash"),
			IsSkip: false,
		},
		"path suffix equal": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".git/index.lock", 0)),
			Sk:     msync.PathSuffixSkip(".git/index.lock"),
			IsSkip: true,
		},
		"path suffix": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("somerepo/.git/index.lock", 0)),
			Sk:     msync.PathSuffixSkip(".git/index.lock"),
			IsSkip: true,
		},
		"path suffix part": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("somerepo/troll.git/index.lock", 0)),
			Sk:     msync.PathSuffixSkip(".git/index.lock"),
			IsSkip: false,
		},
		"path suffix too short": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("git/index.lock", 0)),
			Sk:     msync.PathSuffixSkip(".git/index.lock"),
			IsSkip: false,
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			if isSkip := test.Sk.IsSkip(test.Ev); isSkip != test.IsSkip {
				t.Fatalf("want isSkip = %t; got %t", test.IsSkip, isSkip)
			}
		})
	}
}

func TestDirectorySkip(t *testing.T) {
	tmpDir, err := ioutil.TempDir("", "skipper")
	if err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
	defer os.RemoveAll(tmpDir)

	var (
		ds = msync.DirectorySkip("dir")
	)

	if err := ds.Initialize(tmpDir); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if _, err := os.Lstat(filepath.Join(tmpDir, string(ds))); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
}
