package machine

import (
	"errors"
	"strings"

	"koding/klient/config"

	"github.com/koding/logging"
)

var (
	// ErrMachineNotFound indicates that provided machine cannot be found.
	ErrMachineNotFound = errors.New("machine not found")
)

// DefaultLogger is a logger which can be used in machine related objects as
// a fallback logger when Log option is not provided.
var DefaultLogger = logging.NewCustom("machine", config.Konfig.Debug)

// Cacher defines objects that can be cached.
type Cacher interface {
	Cache() error // Commit underlying data to external cache.
}

// ID is a unique identifier of the machine.
type ID string

// IDSlice represents a set of machine IDs.
type IDSlice []ID

// Less provides a comparator for lexicographical ordering.
func (ids IDSlice) Less(i, j int) bool {
	return string(ids[i]) < string(ids[j])
}

// StringSlice converts ID to string slice.
func (ids IDSlice) StringSlice() []string {
	ss := make([]string, len(ids))
	for i := range ids {
		ss[i] = string(ids[i])
	}

	return ss
}

// String implements fmt.Stringer interface. It pretty prints machine IDs.
func (ids IDSlice) String() string {
	return strings.Join(ids.StringSlice(), ", ")
}

// Metadata stores additional information about single machine.
type Metadata struct {
	Owner string `json:"owner"`
	Label string `json:"label"`
	Stack string `json:"stack"`
	Team  string `json:"team"`
}
