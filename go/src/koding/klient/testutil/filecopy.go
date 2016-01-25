package testutil

import (
	"io"
	"os"
)

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

// FileCopy copies file from dst to src, overwriting src if it exists.
//
// Upon successful calls fsync on the file.
func FileCopy(src, dst string) error {
	fsrc, err := os.Open(src)
	if err != nil {
		return err
	}
	defer fsrc.Close()

	fi, err := fsrc.Stat()
	if err != nil {
		return err
	}

	fdst, err := os.OpenFile(dst, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, fi.Mode())
	if err != nil {
		return err
	}

	_, err = io.Copy(fdst, fsrc)
	return nonil(err, fdst.Sync(), fdst.Close())
}
