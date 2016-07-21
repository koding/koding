package fs

import (
	"os"
	"testing"
)

func TestFileDiskImplementsBlockDevice(t *testing.T) {
	var raw interface{}
	raw = new(FileDisk)
	if _, ok := raw.(BlockDevice); !ok {
		t.Fatal("FileDisk should be a BlockDevice")
	}
}

func TestFileDisk_NewDiskFile_Dir(t *testing.T) {
	f, err := os.Open(os.TempDir())
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	defer f.Close()

	_, err = NewFileDisk(f)
	if err == nil {
		t.Fatal("should error if directory")
	}
}
