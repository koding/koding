package fuseklient

import (
	"fmt"
	"path/filepath"

	"github.com/koding/fuseklient/transport"
)

type DirInitializer struct {
	// Transport is used for two way communication with user VM.
	transport.Transport

	RootDir *Dir

	IgnoreFolders []string

	DirEntriesList map[string]*Dir
}

func NewDirInitializer(t transport.Transport, root *Dir) *DirInitializer {
	return &DirInitializer{
		Transport:      t,
		RootDir:        root,
		DirEntriesList: map[string]*Dir{root.Path: root},
	}
}

func (d *DirInitializer) Initialize() error {
	res, err := d.Transport.ReadDir(d.RootDir.Path, true)
	if err != nil {
		return err
	}

	d.DirEntriesList = map[string]*Dir{d.RootDir.Path: d.RootDir}

	for _, file := range res.Files {
		fmt.Println("DirInitializer#Initialize", file.FullPath, d.RootDir.Path)

		// ignore root directory since it was set above
		if file.FullPath == d.RootDir.Path {
			continue
		}

		// get parent directory of entry; we assume lexical ordering of folders
		// and that parentDir will be there when an entry is read
		parentDirPath := filepath.Dir(file.FullPath)
		parentDir, ok := d.DirEntriesList[parentDirPath]
		if !ok {
			if parentDir, ok = d.DirEntriesList["/"]; !ok {
				return fmt.Errorf("no parent directory: %s", parentDirPath)
			}
		}

		e := newTempEntry(file)
		node, err := parentDir.initializeChild(e)
		if err != nil {
			return err
		}

		if file.IsDir {
			dir := node.(*Dir)
			d.DirEntriesList[file.FullPath] = dir
		}
	}

	return nil
}
