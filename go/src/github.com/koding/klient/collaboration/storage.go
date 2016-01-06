package collaboration

import (
	"errors"
)

var (
	ErrUserNotFound = errors.New("User not found")
)

// Option contains user specific settings
type Option struct {
	// Permananet means the user is shared
	Permanent bool   `json:"permanent"`
	Test      string `json:"test"`
}

type Storage interface {
	// Get returns the user property for a given user
	Get(username string) (*Option, error)

	// GetAll returns all users with their options
	GetAll() (map[string]*Option, error)

	// Set adds the given username and it's option. If there is a
	// username already it will be overwritten
	Set(string, *Option) error

	// Delete deletes the given username
	Delete(string) error

	// Close closes the connection to the storage. For in memory
	// implementations this can be a no-op operation
	Close() error
}
