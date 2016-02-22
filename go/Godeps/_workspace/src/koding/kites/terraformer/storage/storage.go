// Package storage provides backend storage systems
package storage

import "io"

// nonil returns first non-nil error it encounters
func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

// Interface is a contract between different types of storage systems
type Interface interface {
	Write(string, io.Reader) error
	Read(string) (io.Reader, error) // TODO(rjeczalik): io.Reader -> io.ReadCloser?
	Remove(string) error
	Clone(string, Interface) error
	BasePath() (string, error)
}
