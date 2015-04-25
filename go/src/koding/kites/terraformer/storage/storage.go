package storage

import "io"

// Interface is a contract between different types of storage systems
type Interface interface {
	Write(string, io.Reader) error
	Read(string) (io.Reader, error)
	Remove(string) error
	Clone(string, Interface) error
	BasePath() (string, error)
}
