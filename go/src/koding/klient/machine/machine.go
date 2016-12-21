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

// ID is a unique identifier of the machine.
type ID string

// IDSlice represents a set of machine IDs.
type IDSlice []ID

// String implements fmt.Stringer interface. It pretty prints machine IDs.
func (ids IDSlice) String() string {
	strs := make([]string, len(ids))
	for i := range ids {
		strs[i] = string(ids[i])
	}

	return strings.Join(strs, ", ")
}
