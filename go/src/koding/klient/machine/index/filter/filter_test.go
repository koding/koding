package filter_test

import (
	"testing"

	"koding/klient/machine/index/filter"
)

func TestFilter(t *testing.T) {
	tests := map[string]struct {
		Path   string
		F      filter.Filter
		IsSkip bool
	}{
		"directory itself": {
			Path:   ".Trash",
			F:      filter.DirectorySkip(".Trash"),
			IsSkip: true,
		},
		"file inside directory": {
			Path:   ".Trash/file.txt",
			F:      filter.DirectorySkip(".Trash"),
			IsSkip: true,
		},
		"similar prefix": {
			Path:   ".Trasher/file.txt",
			F:      filter.DirectorySkip(".Trash"),
			IsSkip: false,
		},
		"in the middle similar": {
			Path:   "aa/.Trasher/file.txt",
			F:      filter.DirectorySkip(".Trash"),
			IsSkip: false,
		},
		"path suffix equal": {
			Path:   ".git/index.lock",
			F:      filter.PathSuffixSkip(".git/index.lock"),
			IsSkip: true,
		},
		"path suffix": {
			Path:   "somerepo/.git/index.lock",
			F:      filter.PathSuffixSkip(".git/index.lock"),
			IsSkip: true,
		},
		"path suffix part": {
			Path:   "somerepo/troll.git/index.lock",
			F:      filter.PathSuffixSkip(".git/index.lock"),
			IsSkip: false,
		},
		"path suffix too short": {
			Path:   "git/index.lock",
			F:      filter.PathSuffixSkip(".git/index.lock"),
			IsSkip: false,
		},
		"git branch lock": {
			Path:   "notify/.git/refs/heads/master.lock",
			F:      filter.NewRegexSkip(`\.git/refs/heads/[^\s]+\.lock$`),
			IsSkip: true,
		},
		"git stash reference lock": {
			Path:   "notify/.git/index.stash.31012.lock",
			F:      filter.NewRegexSkip(`\.git/index\.stash\.\d+\.lock$`),
			IsSkip: true,
		},
	}

	for name, test := range tests {
		test := test // Capture range variable.
		t.Run(name, func(t *testing.T) {
			t.Parallel()

			if err := test.F.Check(test.Path); test.IsSkip != (err == filter.SkipPath) {
				t.Fatalf("want (err == filter.SkipPath) = %t; got %v", test.IsSkip, err)
			}
		})
	}
}

func TestWithError(t *testing.T) {
	const (
		errmsg  = "test error"
		fullmsg = errmsg + " (path: .Trash)"
	)

	if e := filter.NewWithError(filter.DirectorySkip(".Trash"), errmsg).Check(".Trash"); e.Error() != fullmsg {
		t.Fatalf("want err.Error() = %s; got %s", fullmsg, e)
	}
}
