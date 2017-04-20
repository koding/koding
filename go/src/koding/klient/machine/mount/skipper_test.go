package mount_test

import (
	"context"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"koding/klient/machine/index"
	"koding/klient/machine/mount"
	msync "koding/klient/machine/mount/sync"
)

func TestIsSkip(t *testing.T) {
	ctx := context.Background()
	tests := map[string]struct {
		Ev     *msync.Event
		Sk     mount.Skipper
		IsSkip bool
	}{
		"directory itself": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".Trash", index.PriorityMedium, 0)),
			Sk:     mount.DirectorySkip(".Trash"),
			IsSkip: true,
		},
		"file inside directory": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".Trash/file.txt", index.PriorityMedium, 0)),
			Sk:     mount.DirectorySkip(".Trash"),
			IsSkip: true,
		},
		"similar prefix": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".Trasher/file.txt", index.PriorityMedium, 0)),
			Sk:     mount.DirectorySkip(".Trash"),
			IsSkip: false,
		},
		"in the middle": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("aa/.Trasher/file.txt", index.PriorityMedium, 0)),
			Sk:     mount.DirectorySkip(".Trash"),
			IsSkip: false,
		},
		"path suffix equal": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange(".git/index.lock", index.PriorityMedium, 0)),
			Sk:     mount.PathSuffixSkip(".git/index.lock"),
			IsSkip: true,
		},
		"path suffix": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("somerepo/.git/index.lock", index.PriorityMedium, 0)),
			Sk:     mount.PathSuffixSkip(".git/index.lock"),
			IsSkip: true,
		},
		"path suffix part": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("somerepo/troll.git/index.lock", index.PriorityMedium, 0)),
			Sk:     mount.PathSuffixSkip(".git/index.lock"),
			IsSkip: false,
		},
		"path suffix too short": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("git/index.lock", index.PriorityMedium, 0)),
			Sk:     mount.PathSuffixSkip(".git/index.lock"),
			IsSkip: false,
		},
		"git branch lock": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("notify/.git/refs/heads/master.lock", index.PriorityMedium, 0)),
			Sk:     mount.NewRegexSkip(`\.git/refs/heads/[^\s]+\.lock$`),
			IsSkip: true,
		},
		"git stash reference lock": {
			Ev:     msync.NewEvent(ctx, nil, index.NewChange("notify/.git/index.stash.31012.lock", index.PriorityMedium, 0)),
			Sk:     mount.NewRegexSkip(`\.git/index\.stash\.\d+\.lock$`),
			IsSkip: true,
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
		ds = mount.DirectorySkip("dir")
	)

	if err := ds.Initialize(tmpDir); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}

	if _, err := os.Lstat(filepath.Join(tmpDir, string(ds))); err != nil {
		t.Fatalf("want err = nil; got %v", err)
	}
}
