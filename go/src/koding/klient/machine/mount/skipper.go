package mount

import (
	"regexp"
	"runtime"
	"strings"

	msync "koding/klient/machine/mount/sync"
)

// DefaultSkipper contains a default set of non-synced file rules.
var DefaultSkipper Skipper = MultiSkipper{
	OsSkip(DirectorySkip(".Trash"), "darwin"),      // OSX trash directory.
	OsSkip(DirectorySkip(".Trashes"), "darwin"),    // OSX trash directory.
	PathSuffixSkip(".git/index.lock"),              // git index lock file.
	PathSuffixSkip(".git/refs/stash.lock"),         // git stash lock file.
	PathSuffixSkip(".git/HEAD.lock"),               // git HEAD lock.
	PathSuffixSkip(".git/ORIG_HEAD.lock"),          // git ORIG_HEAD lock.
	NewRegexSkip(`\.git/refs/heads/[^\s]+\.lock$`), // git branch lock.
	NewRegexSkip(`\.git/index\.stash\.\d+\.lock$`), // git stash ref. lock.
}

// Skipper describes a file or set of files which are not going to be synced.
type Skipper interface {
	// Initialize ensures object which is not going to be synced.
	Initialize(string) error

	// IsSkip tells whether Event should be skipped or not.
	IsSkip(*msync.Event) bool
}

// MultiSkipper is a set of rules on files that should not be synced with remote
// machine. It contains OS specific files or entries that do not have to be sent
// to remote machine like git index lock file etc.
type MultiSkipper []Skipper

// Initialize initializes all underlying Skippers.
func (ms MultiSkipper) Initialize(wd string) (err error) {
	for _, s := range ms {
		if e := s.Initialize(wd); e != nil && err == nil {
			err = e
		}
	}

	return err
}

// IsSkip runs all underlying Skippers and returns true if any of them returns
// true.
func (ms MultiSkipper) IsSkip(ev *msync.Event) bool {
	for _, s := range ms {
		if ok := s.IsSkip(ev); ok {
			return true
		}
	}

	return false
}

// NeverSkip implements Skipper interface. It never skips the Event.
type NeverSkip struct{}

// Initialize always returns true.
func (NeverSkip) Initialize(_ string) error { return nil }

// IsSkip never skips the evvent.
func (NeverSkip) IsSkip(_ *msync.Event) bool { return false }

// DirectorySkip creates a directory which content will not be synced.
type DirectorySkip string

// Initialize checks if stored file exists and if it is a directory. If not
// exist directory will be created. If not a directory, an error is returned.
func (ds DirectorySkip) Initialize(wd string) error {
	return nil
}

// IsSkip returns true for all events which are created in given path and for
// the path itself.
func (ds DirectorySkip) IsSkip(ev *msync.Event) bool {
	path := ev.Change().Path()
	return path == string(ds) || (strings.HasPrefix(path, string(ds)) && path[len(ds)] == '/')
}

// PathSuffixSkip skips all paths that end with provided suffix.
type PathSuffixSkip string

// Initialize always returns true.
func (PathSuffixSkip) Initialize(_ string) error { return nil }

// IsSkip returns true for all change paths that ends with provided suffix.
func (pss PathSuffixSkip) IsSkip(ev *msync.Event) bool {
	path := ev.Change().Path()
	return path == string(pss) || (strings.HasSuffix(path, string(pss)) && path[len(path)-len(pss)-1] == '/')
}

// OsSkip returns provided skipper only when goos name matches current system. It
// returns NeverSkip in other cases.
func OsSkip(s Skipper, goos string) Skipper {
	if runtime.GOOS == goos {
		return s
	}

	return NeverSkip{}
}

// RegexSkip skips all paths that matches stored regural expression.
type RegexSkip struct {
	re *regexp.Regexp
}

// NewRegexSkip creates a new RegexSkip object or panics if provided expression
// cannot be compilled.
func NewRegexSkip(expr string) *RegexSkip {
	return &RegexSkip{
		re: regexp.MustCompile(expr),
	}
}

// Initialize always returns true.
func (rs *RegexSkip) Initialize(_ string) error { return nil }

// IsSkip returns true when provided event's path matches stored regexp.
func (rs *RegexSkip) IsSkip(ev *msync.Event) bool {
	return rs.re.MatchString(ev.Change().Path())
}
