package transport

import "os"

// Transport defines communication between this package and user VM.
type Transport interface {
	Trip(string, interface{}, interface{}) error
	CreateDir(string, os.FileMode) error
	ReadDir(string, []string) (FsReadDirRes, error)
	Rename(string, string) error
	Remove(string) error
	ReadFile(string) (FsReadFileRes, error)
	WriteFile(string, []byte) error
}
