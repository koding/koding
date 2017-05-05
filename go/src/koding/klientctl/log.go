package main

import (
	"errors"
	"fmt"
	"path/filepath"

	"koding/klientctl/endpoint/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

func LogUpload(c *cli.Context, log logging.Logger, _ string) (int, error) {
	f := &machine.UploadedFile{
		File: c.Args().Get(0),
	}

	if f.File == "" {
		return 1, errors.New("file path is empty or missing")
	}

	if !filepath.IsAbs(f.File) {
		var err error
		f.File, err = filepath.Abs(f.File)
		if err != nil {
			return 1, err
		}
	}

	if err := machine.Upload(f); err != nil {
		return 1, err
	}

	fmt.Println(f.URL)

	return 0, nil
}
