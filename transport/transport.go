package transport

// Transport defines communication between this package and user VM.
type Transport interface {
	Trip(string, interface{}, interface{}) error
	CreateDirectory(string) error
	ReadDirectory(string, []string) (FsReadDirectoryRes, error)
	Rename(string, string) error
	Remove(string) error
	WriteFile(string, []byte) error
	ReadFile(string) (FsReadFileRes, error)
}
