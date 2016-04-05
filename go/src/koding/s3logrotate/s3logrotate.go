package s3logrotate

import (
	"archive/zip"
	"bytes"
	"os"
	"path/filepath"
)

type Client struct {
	FileSizeLimit int64
	Files         []string
	Uploader      *Uploader
}

func New(limit int64, u *Uploader, files ...string) *Client {
	return &Client{
		FileSizeLimit: limit,
		Files:         files,
		Uploader:      u,
	}
}

func (c *Client) ReadFile(name string) ([]byte, error) {
	file, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	stat, err := os.Stat(name)
	if err != nil {
		return nil, err
	}

	size := c.FileSizeLimit
	if stat.Size() < c.FileSizeLimit {
		size = stat.Size()
	}

	buf := make([]byte, size)
	if _, err := file.ReadAt(buf, stat.Size()-size); err != nil {
		return nil, err
	}

	return buf, nil
}

func (c *Client) Zip(files map[string][]byte) ([]byte, error) {
	b := new(bytes.Buffer)
	w := zip.NewWriter(b)

	for file, bytes := range files {
		f, _ := w.Create(filepath.Base(file))
		f.Write(bytes)
	}

	if err := w.Close(); err != nil {
		return nil, err
	}

	return b.Bytes(), nil
}

func (c *Client) ReadAndUpload() error {
	f := map[string][]byte{}
	for _, file := range c.Files {
		f[file], _ = c.ReadFile(file)
	}

	b, err := c.Zip(f)
	if err != nil {
		return err
	}

	return c.Uploader.Upload(b)
}
