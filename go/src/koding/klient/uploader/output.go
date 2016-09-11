package uploader

import (
	"io"
	"os"
	"path/filepath"
)

type File struct {
	F      *os.File
	Upload func(string) error
}

var _ io.WriteCloser = (*File)(nil)

func (f *File) Write(p []byte) (int, error) {
	return f.F.Write(p)
}

func (f *File) Close() error {
	return nonil(f.F.Close(), f.Upload(f.F.Name()))
}

func (up *Uploader) Output(path string) (io.WriteCloser, error) {
	os.MkdirAll(filepath.Dir(path), 0755)

	f, err := os.Create(path)
	if err != nil {
		return nil, err
	}

	return &File{
		F: f,
		Upload: func(path string) error {
			_, err := up.UploadFile(path, 0)
			return err
		},
	}, nil
}
