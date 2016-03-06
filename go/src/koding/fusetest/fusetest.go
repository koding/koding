package fusetest

import (
	"io/ioutil"
	"os"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

// Fusetest runs common file & dir operations on already mounted folder
// then checks if local mount and remote VM are synchronized using ssh.
type Fusetest struct {
	Machine  string
	MountDir string

	T *testing.T

	*Remote
}

func NewFusetest(machine string) (*Fusetest, error) {
	r, err := NewRemote(machine)
	if err != nil {
		return nil, err
	}

	mountDir, err := ioutil.TempDir(r.local, "tests")
	if err != nil {
		return nil, err
	}

	return &Fusetest{
		Machine:  machine,
		MountDir: mountDir,
		T:        &testing.T{},
		Remote:   r,
	}, nil
}

func (f *Fusetest) RunAllTests() {
	// dir ops
	f.TestMkDir()
	f.TestReadDir()
	f.TestRmDir()

	// file ops
	f.TestCreateFile()
	f.TestReadFile()
	f.TestWriteFile()

	// common ops
	f.TestRename()
	f.TestCpOutToIn()

	os.RemoveAll(f.MountDir)
}

func (f *Fusetest) setupConvey(name string, fn func(string)) {
	Convey(name, f.T, createDir(f.MountDir, name, func(dirPath string) {
		fn(dirPath)
	}))
}
