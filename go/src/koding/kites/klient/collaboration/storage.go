package collaboration

import (
	"errors"
)

var (
	ErrUserNotFound = errors.New("User not found")
)

type Storage interface {
	Get(string) (string, error)
	GetAll() ([]string, error)
	Set(string, string) error
	Delete(string) error
	Close() error
}
