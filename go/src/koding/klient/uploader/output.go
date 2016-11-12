package uploader

import (
	"io"
	"os"
	"path/filepath"

	multierror "github.com/hashicorp/go-multierror"
)

var LogFiles = []string{
	"/var/log/klient.log",
	"/var/log/klient.err",
	"/var/log/kd.log",
	"/var/log/upstart/klient.log",
	"/var/log/upstart/klient.err",
	"/var/log/upstart/kd.log",
	"/Library/Logs/klient.log",
	"/Library/Logs/kd.log",
	"/var/log/cloud-init-output.log",
	"/var/log/cloud-init.log",
	"/var/lib/koding/user-data.sh",
}

func FixPerms() error {
	const read = 0444

	var merr error

	for _, file := range LogFiles {
		fi, err := os.Stat(file)
		if err != nil {
			if !os.IsNotExist(err) {
				merr = multierror.Append(merr, err)
			}

			continue
		}

		if (fi.Mode() & read) != read {
			err = os.Chmod(fi.Name(), fi.Mode()|read)
			if err != nil {
				merr = multierror.Append(merr, err)
			}
		}
	}

	return merr
}

type File struct {
	F      *os.File
	Upload func() error
}

var _ io.WriteCloser = (*File)(nil)

func (f *File) Write(p []byte) (int, error) {
	return f.F.Write(p)
}

func (f *File) Close() error {
	return nonil(f.F.Close(), f.Upload())
}

func (up *Uploader) Output(path string) (io.WriteCloser, error) {
	os.MkdirAll(filepath.Dir(path), 0755)

	f, err := os.Create(path)
	if err != nil {
		return nil, err
	}

	return &File{
		F: f,
		Upload: func() error {
			_, err := up.UploadFile(path, 0)
			return err
		},
	}, nil
}
