package transport

import (
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"syscall"

	"koding/klient/command"
)

var diskCachePathPrefix = "fuseklient-diskcache"

// NewDiskTransport is the required initializer for DiskTransport. It accepts
// path where to create cache folder; if empty path is specified it creates a
// folder at temp location.
func NewDiskTransport(diskPath string) (*DiskTransport, error) {
	if diskPath == "" {
		var err error
		if diskPath, err = ioutil.TempDir("", diskCachePathPrefix); err != nil {
			return nil, err
		}
	}

	return &DiskTransport{
		DiskPath: diskPath,
	}, nil
}

// DiskTransport is an implementation of Transport that reads files and dirs
// from disk.
type DiskTransport struct {
	DiskPath string
}

func (d *DiskTransport) CreateDir(path string, mode os.FileMode) error {
	return os.MkdirAll(d.fullPath(path), mode)
}

func (d *DiskTransport) ReadDir(path string, r bool) (*ReadDirRes, error) {
	entries, err := readDirectory(d.fullPath(path), r, nil)
	if err != nil {
		return nil, err
	}

	// remove disk path prefix from entries
	for i, entry := range entries {
		entry.FullPath = d.relativePath(entry.FullPath)
		entries[i] = entry
	}

	return &ReadDirRes{Files: entries}, nil
}

func (d *DiskTransport) Rename(oldName, newName string) error {
	return rename(d.fullPath(oldName), d.fullPath(newName))
}

func (d *DiskTransport) Remove(path string) error {
	return remove(d.fullPath(path), true)
}

func (d *DiskTransport) ReadFile(path string) (*ReadFileRes, error) {
	resp, err := readFile(d.fullPath(path), 0, 0)
	if err != nil {
		return nil, err
	}

	return readFileMarshal(resp)
}

func (d *DiskTransport) ReadFileAt(path string, offset, blockSize int64) (*ReadFileRes, error) {
	resp, err := readFile(d.fullPath(path), offset, blockSize)
	if err != nil {
		return nil, err
	}

	return readFileMarshal(resp)
}

func (d *DiskTransport) WriteFile(path string, data []byte) error {
	// path, data, doNotOverwrite, append
	_, err := writeFile(d.fullPath(path), data, false, false)
	return err
}

func (d *DiskTransport) Exec(cmd string) (*ExecRes, error) {
	c := exec.Command("/bin/bash", "-c", cmd)
	res, err := command.NewOutput(c)
	if err != nil {
		return nil, err
	}

	return &ExecRes{
		Stdout:     res.Stdout,
		Stderr:     res.Stderr,
		ExitStatus: res.ExitStatus,
	}, nil
}

func (d *DiskTransport) GetDiskInfo(path string) (*GetDiskInfoRes, error) {
	return getDiskInfo(d.fullPath(path))
}

func (d *DiskTransport) GetInfo(path string) (*GetInfoRes, error) {
	res, err := getInfo(d.fullPath(path))
	if err != nil {
		return nil, err
	}

	// remove disk path prefix
	res.FullPath = d.relativePath(res.FullPath)

	return res, nil
}

func (d *DiskTransport) GetRemotePath() string {
	return d.DiskPath
}

// fullPath prefixes internal root disk path with the specified path. This is
// used to specify the path in requests.
func (d *DiskTransport) fullPath(path string) string {
	return filepath.Join(d.DiskPath, path)
}

// relativePath removes internal disk path prefix from specified path. This is
// used when cleaning up responses.
func (d *DiskTransport) relativePath(path string) string {
	return strings.TrimPrefix(path, d.DiskPath)
}

func readFileMarshal(resp map[string]interface{}) (*ReadFileRes, error) {
	content, ok := resp["content"]
	if !ok {
		return nil, errors.New("'content' is not a byte slice")
	}

	byteContent, ok := content.([]byte)
	if !ok {
		return nil, errors.New("no 'content' in response")
	}

	return &ReadFileRes{Content: byteContent}, nil
}

///// COPIED FROM KLIENT. TODO: fix this.

func readDirectory(p string, r bool, i []string) ([]*GetInfoRes, error) {
	var ls []*GetInfoRes

	walkerFn := func(path string, f os.FileInfo, err error) error {
		// no use in returning root level directory that's being traversed
		if path == p {
			return nil
		}

		if err != nil {
			return err
		}

		// skip ignored folders
		if f.IsDir() {
			for _, ignore := range i {
				// adding / is required to prevent partial matching
				if strings.Contains(path, "/"+ignore+"/") {
					return filepath.SkipDir
				}
			}
		}

		fileInfo := makeFileEntry(path, f)
		ls = append(ls, fileInfo)

		if !r && f.IsDir() {
			return filepath.SkipDir
		}

		return nil
	}

	if err := filepath.Walk(p, walkerFn); err != nil {
		return nil, err
	}

	return ls, nil
}

func makeFileEntry(fullPath string, fi os.FileInfo) *GetInfoRes {
	var (
		readable bool
		writable bool
	)

	f, err := os.OpenFile(fullPath, os.O_RDONLY, 0)
	if f != nil {
		f.Close()
	}

	// If there is no error in attempting to open the file for Reading,
	// it is readable.
	if err == nil {
		readable = true
	}

	f, err = os.OpenFile(fullPath, os.O_WRONLY, 0)
	if f != nil {
		f.Close()
	}

	// If there are no error in attempting to open the file for Writing,
	// it is writable.
	if err == nil {
		writable = true
	}

	entry := &GetInfoRes{
		Name:     fi.Name(),
		Exists:   true,
		FullPath: fullPath,
		IsDir:    fi.IsDir(),
		Size:     uint64(fi.Size()),
		Mode:     fi.Mode(),
		Time:     fi.ModTime(),
		Readable: readable,
		Writable: writable,
	}

	if fi.Mode()&os.ModeSymlink != 0 {
		symlinkInfo, err := os.Stat(path.Dir(fullPath) + "/" + fi.Name())
		if err != nil {
			entry.IsBroken = true
			return entry
		}
		entry.IsDir = symlinkInfo.IsDir()
		entry.Size = uint64(symlinkInfo.Size())
		entry.Mode = symlinkInfo.Mode()
		entry.Time = symlinkInfo.ModTime()
	}

	return entry
}

func writeFile(filename string, data []byte, doNotOverwrite, Append bool) (int, error) {
	flags := os.O_RDWR | os.O_CREATE
	if doNotOverwrite {
		flags |= os.O_EXCL
	}

	if !Append {
		flags |= os.O_TRUNC
	} else {
		flags |= os.O_APPEND
	}

	file, err := os.OpenFile(filename, flags, 0666)
	if err != nil {
		return 0, err
	}

	defer file.Close()

	return file.Write(data)
}

func readFile(path string, offset, blockSize int64) (map[string]interface{}, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	fi, err := file.Stat()
	if err != nil {
		return nil, err
	}

	if fi.Size() > 50*1024*1024 && offset == 0 && blockSize == 0 {
		return nil, fmt.Errorf("File larger than 50MiB. Please use offset and/or blockSize")
	}

	var buf []byte

	// read entire file from start to end
	if offset == 0 && blockSize == 0 {
		buf = make([]byte, fi.Size())
		if _, err = io.ReadFull(file, buf); err != nil {
			return nil, err
		}

		return map[string]interface{}{"content": buf}, nil
	}

	size := blockSize

	// read entire file from offset to end
	if offset != 0 && blockSize == 0 {
		size = fi.Size() - offset
	}

	// read file from start till blocksize
	// if file size is less than blocksize, then return file sized block
	if offset == 0 && blockSize != 0 {
		if fi.Size() < blockSize {
			size = fi.Size()
		}
	}

	// read file from offset till blockSize
	// if file size from offset is less than blockSize, then return offset
	// to end of file sized block
	if offset != 0 && blockSize != 0 {
		if fi.Size()-offset < blockSize {
			size = fi.Size() - offset
		}
	}

	buf = make([]byte, size)
	if _, err = file.ReadAt(buf, offset); err != nil {
		return nil, err
	}

	return map[string]interface{}{"content": buf}, nil
}

func rename(oldname, newname string) error {
	return os.Rename(oldname, newname)
}

func remove(path string, recursive bool) error {
	if recursive {
		return os.RemoveAll(path)
	}

	return os.Remove(path)
}

func getDiskInfo(path string) (*GetDiskInfoRes, error) {
	stfs := syscall.Statfs_t{}
	if err := syscall.Statfs(path, &stfs); err != nil {
		return nil, err
	}

	di := &GetDiskInfoRes{
		BlockSize:   uint32(stfs.Bsize),
		BlocksTotal: stfs.Blocks,
		BlocksFree:  stfs.Bfree,
	}
	di.BlocksUsed = di.BlocksTotal - di.BlocksFree

	return di, nil
}

func getInfo(path string) (*GetInfoRes, error) {
	fi, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			// The file doesn't exists, let the client side let this know
			// instead of returning error
			return &GetInfoRes{
				Name:   path,
				Exists: false,
			}, nil
		}

		return nil, err
	}

	return makeFileEntry(path, fi), nil
}
