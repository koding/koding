// Package zipfs implements the http.FileSystem interface
// for zip archives.
package zipfs

import (
	"archive/zip"
	"bytes"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

func NewZipFS(z *zip.Reader) http.FileSystem {
	return &zipFS{zip: z, cache: make(map[string][]byte)}
}

type zipFS struct {
	zip   *zip.Reader
	cache map[string][]byte
}

var _ http.FileSystem = new(zipFS)

func (fs *zipFS) Open(name string) (http.File, error) {
	// name will be "/" or "/file/name"
	for _, entry := range fs.zip.File {
		if entry.Name == name[1:] {
			f, err := entry.Open()
			if err != nil {
				return nil, err
			}
			data, err := ioutil.ReadAll(f)
			if err != nil {
				return nil, err
			}
			z := &zipFile{Info: entry.FileHeader, Data: bytes.NewReader(data)}
			return z, nil
		}
		if entry.Mode().IsDir() && entry.Name == name[1:]+"/" {
			// fake directory.
			dir := &zipDir{Info: entry.FileHeader}
			for _, subentry := range fs.zip.File {
				if strings.HasPrefix(subentry.Name, entry.Name) && subentry != entry {
					clone := *subentry
					clone.Name = subentry.Name[len(entry.Name):]
					dir.Files = append(dir.Files, &clone)
				}
			}
			return dir, nil
		}
	}
	return nil, os.ErrNotExist
}

type zipFile struct {
	Info zip.FileHeader
	Data *bytes.Reader
}

func (f *zipFile) Close() error                              { return nil }
func (f *zipFile) Stat() (os.FileInfo, error)                { return f.Info.FileInfo(), nil }
func (f *zipFile) Readdir(count int) ([]os.FileInfo, error)  { return nil, os.ErrInvalid }
func (f *zipFile) Read(s []byte) (int, error)                { return f.Data.Read(s) }
func (f *zipFile) Seek(off int64, whence int) (int64, error) { return f.Data.Seek(off, whence) }

var _ http.File = new(zipFile)

type zipDir struct {
	Info  zip.FileHeader
	Files []*zip.File
}

func (f *zipDir) Close() error                              { return nil }
func (f *zipDir) Stat() (os.FileInfo, error)                { return f.Info.FileInfo(), nil }
func (f *zipDir) Read(s []byte) (int, error)                { return 0, os.ErrInvalid }
func (f *zipDir) Seek(off int64, whence int) (int64, error) { return 0, os.ErrInvalid }

func (f *zipDir) Readdir(count int) ([]os.FileInfo, error) {
	if len(f.Files) == 0 {
		return nil, io.EOF
	}
	if count > len(f.Files) {
		count = len(f.Files)
	}
	infos := make([]os.FileInfo, count)
	for i, f := range f.Files {
		if i >= count {
			break
		}
		infos[i] = f.FileInfo()
	}
	f.Files = f.Files[count:]
	return infos, nil
}
