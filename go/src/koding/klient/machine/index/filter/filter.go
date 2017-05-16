package filter

import (
	"errors"
	"regexp"
	"runtime"
	"strings"
)

// SkipPath indicates that provided filter does not want provided path to pass.
var SkipPath = errors.New("skip this path")

// Filter defines interface for checking if provided file or path is filtered.
type Filter interface {
	// Check should return non nil error when provided path is filtered.
	Check(path string) error
}

// MultiFilter satisfies Filter interface. It can be used to bind multiple
// filters.
type MultiFilter []Filter

// Check runs all underlying Filters and returns first non-nil error it gets.
func (mf MultiFilter) Check(path string) (err error) {
	for _, f := range mf {
		if err = f.Check(path); err != nil {
			return err
		}
	}

	return nil
}

// NeverSkip implements Filter interface. It never skips provided path.
type NeverSkip struct{}

// Check always returns nil.
func (NeverSkip) Check(_ string) error { return nil }

// DirectorySkip filters path with a given directory.
type DirectorySkip string

// Check returns SkipPath error when provided path contains skipped directory.
func (ds DirectorySkip) Check(path string) error {
	if strings.HasSuffix(path, string(ds)) ||
		strings.Index(path, "/"+string(ds)+"/") >= 0 ||
		strings.HasPrefix(path, string(ds)+"/") {
		return SkipPath
	}

	return nil
}

// PathSuffixSkip filters all paths that end with provided suffix.
type PathSuffixSkip string

// Check returns true for all change paths that ends with provided suffix.
func (pss PathSuffixSkip) Check(path string) error {
	if path == string(pss) || (strings.HasSuffix(path, string(pss)) && path[len(path)-len(pss)-1] == '/') {
		return SkipPath
	}

	return nil
}

// OsSkip returns provided filter only when goos name matches current system. It
// returns NeverSkip in other cases.
func OsSkip(f Filter, goos string) Filter {
	if runtime.GOOS == goos {
		return f
	}

	return NeverSkip{}
}

// RegexSkip filters all paths that matches stored regural expression.
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

// Check returns SkipErr when provided path matches stored regexp.
func (rs *RegexSkip) Check(path string) error {
	if rs.re.MatchString(path) {
		return SkipPath
	}

	return nil
}

// WithError implements Filter interface. It replaces returned non-nil wrapped
// skipper error with provided one.
type WithError struct {
	f      Filter
	errmsg string
}

// NewWithError creates a new WithError object.
func NewWithError(f Filter, errmsg string) *WithError {
	return &WithError{
		f:      f,
		errmsg: errmsg,
	}
}

// Check runs stored checker and returns err field when internal checker's error
// is non-nil.
func (we *WithError) Check(path string) error {
	if err := we.f.Check(path); err != nil {
		return errors.New(we.errmsg + " (path: " + path + ")")
	}

	return nil
}
