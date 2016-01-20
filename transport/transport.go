package transport

import "os"

// Transport defines communication between this package and user VM.
type Transport interface {
	CreateDir(string, os.FileMode) error
	ReadDir(string, bool, []string) (*ReadDirRes, error)
	Rename(string, string) error
	Remove(string) error
	ReadFile(string) (*ReadFileRes, error)
	WriteFile(string, []byte) error
	Exec(string) (*ExecRes, error)
	GetDiskInfo(string) (*GetDiskInfoRes, error)
	GetInfo(string) (*GetInfoRes, error)
}
