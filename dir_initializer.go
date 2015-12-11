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

func NewDirInitializer(t transport.Transport, root *Dir, ignoreFolders []string) *DirInitializer {
	return &DirInitializer{
		Transport:      t,
		RootDir:        root,
		IgnoreFolders:  ignoreFolders,
		DirEntriesList: map[string]*Dir{root.RemotePath: root},
	}
}

func (d *DirInitializer) Initialize() error {
	req := struct {
		Path          string
		Recursive     bool
		IgnoreFolders []string
	}{
		Path:          d.RootDir.RemotePath,
		Recursive:     true,
		IgnoreFolders: d.IgnoreFolders,
	}
	res := transport.FsReadDirectoryRes{}

	if err := d.Trip("fs.readDirectory", req, &res); err != nil {
		return err
	}

	d.DirEntriesList = map[string]*Dir{d.RootDir.RemotePath: d.RootDir}

	for _, file := range res.Files {
		// ignore root directory since it was set above
		if file.FullPath == d.RootDir.RemotePath {
			continue
		}

		// get parent directory of entry; we assume lexical ordering of folders
		// and that parentDir will be there when an entry is read
		parentDirPath := filepath.Dir(file.FullPath)
		parentDir, ok := d.DirEntriesList[parentDirPath]
		if !ok {
			return fmt.Errorf("no parent directory: %s", parentDirPath)
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
