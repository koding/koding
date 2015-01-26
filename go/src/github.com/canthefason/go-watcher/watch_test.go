package watcher

import (
	"os"
	"testing"
)

func TestPrepareRootDir(t *testing.T) {
	w := &Watcher{}
	dir, err := w.prepareRootDir()
	if err != nil {
		t.Errorf("Expected nil but got %s for prepareRootDir", err)
	}

	workingDir, _ := os.Getwd()
	if dir != workingDir {
		t.Errorf("Expected %s but got %s for prepareRootDir", workingDir, dir)
	}

	w.rootdir = "balcony"
	os.Setenv("GOPATH", "")
	dir, err = w.prepareRootDir()
	if err != ErrPathNotSet {
		t.Errorf("Expected %s but got %s for prepareRootDir", ErrPathNotSet, err)
	}

	os.Setenv("GOPATH", "go")

	dir, err = w.prepareRootDir()
	if err != nil {
		t.Errorf("Expected nil but got %s for prepareRootDir", err)
	}

	if dir != "go/src/balcony" {
		t.Errorf("Expected go/src/balcony but got %s for prepareRootDir", dir)
	}
}
