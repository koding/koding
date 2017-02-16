package fs

import (
	"crypto/md5"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type FileEntry struct {
	Name     string      `json:"name"`
	FullPath string      `json:"fullPath"`
	IsDir    bool        `json:"isDir"`
	Exists   bool        `json:"exists"`
	Size     int64       `json:"size"`
	Mode     os.FileMode `json:"mode"`
	Time     time.Time   `json:"time"`
	IsBroken bool        `json:"isBroken"`
	Readable bool        `json:"readable"`
	Writable bool        `json:"writable"`
}

func NewFileEntry(name string, fullPath string) *FileEntry {
	return &FileEntry{
		Name:     name,
		Exists:   true,
		FullPath: fullPath,
	}
}

func readDirectory(p string, recursive bool, ignoreFolders []string) ([]*FileEntry, error) {
	ls := make([]*FileEntry, 0)
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
			for _, ignore := range ignoreFolders {
				// adding / is required to prevent partial matching
				if strings.Contains(path, "/"+ignore+"/") {
					return filepath.SkipDir
				}
			}
		}

		fileInfo := makeFileEntry(path, f)
		ls = append(ls, fileInfo)

		if !recursive && f.IsDir() {
			return filepath.SkipDir
		}

		return nil
	}

	if err := filepath.Walk(p, walkerFn); err != nil {
		return nil, err
	}

	return ls, nil
}

func glob(glob string) ([]string, error) {
	files, err := filepath.Glob(glob)
	if err != nil {
		return nil, err
	}

	return files, nil
}

// readFile reads file at path and returns content. It optionally takes offset
// and blockSize as args. One difference between this and other generic Read
// ops is this method optimizes returning empty bytes. For example if the
// file size is only 1, but blockSize specified is 10, resulting byte slice will
// be 1. This is done to optimize network traffic.
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

// compareFileWithHash reads from the given file, comparing it with te given hash.
// If the given hash and the hashed contents of the file do not match, an error is
// returned. If there is any problem reading, an error is also returned.
func compareFileWithHash(f string, h string) error {
	file, err := os.OpenFile(f, os.O_RDONLY, 0666)
	if err != nil {
		return err
	}
	defer file.Close()

	// Grab the current hash, and compare it to the expectedHash
	hash := md5.New()
	_, err = io.Copy(hash, file)
	if err != nil {
		return err
	}

	if h != hex.EncodeToString(hash.Sum(nil)) {
		return errors.New(fmt.Sprintf(
			"expected %q's contents to match the %q hash, it does not.",
			file.Name(), h,
		))
	}

	return nil
}

// writeFile implements writing files for the fs.writeFile handler.
func writeFile(params writeFileParams) (int, error) {
	flags := os.O_RDWR | os.O_CREATE
	if params.DoNotOverwrite {
		flags |= os.O_EXCL
	}

	// Only add TRUNC / APPEND flags if no offset has been given.
	if params.Offset == 0 {
		if !params.Append {
			flags |= os.O_TRUNC
		} else {
			flags |= os.O_APPEND
		}
	}

	// if lastHash isn't empty, the caller is requesting to compare it to a hash before
	// being modified. Nothing to do.
	//
	// Only hash the file if doNotOverwrite is false. If we're not able to overwrite
	// it there's no point in comparing hashes since no damage can be done.
	if params.LastContentHash != "" && !params.DoNotOverwrite {
		if err := compareFileWithHash(params.Path, params.LastContentHash); err != nil {
			return 0, err
		}
	}

	file, err := os.OpenFile(params.Path, flags, 0666)
	if err != nil {
		return 0, err
	}

	defer file.Close()

	if params.Offset != 0 {
		return file.WriteAt(params.Content, params.Offset)
	}

	return file.Write(params.Content)
}

var suffixRegexp = regexp.MustCompile(`.((_\d+)?)(\.\w*)?$`)

func uniquePath(name string) (string, error) {
	index := 1
	for {
		_, err := os.Stat(name)
		if err != nil {
			if os.IsNotExist(err) {
				break
			}
			return "", err
		}

		loc := suffixRegexp.FindStringSubmatchIndex(name)
		name = name[:loc[2]] + "_" + strconv.Itoa(index) + name[loc[3]:]
		index++
	}

	return name, nil
}

func getInfo(path string) (*FileEntry, error) {
	fi, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			// The file doesn't exists, let the client side let this know
			// instead of returning error
			return &FileEntry{
				Name:   path,
				Exists: false,
			}, nil
		}

		return nil, err
	}

	return makeFileEntry(path, fi), nil
}

func makeFileEntry(fullPath string, fi os.FileInfo) *FileEntry {
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

	entry := &FileEntry{
		Name:     fi.Name(),
		Exists:   true,
		FullPath: fullPath,
		IsDir:    fi.IsDir(),
		Size:     fi.Size(),
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
		entry.Size = symlinkInfo.Size()
		entry.Mode = symlinkInfo.Mode()
		entry.Time = symlinkInfo.ModTime()
	}

	return entry
}

func setPermissions(name string, mode os.FileMode, recursive bool) error {
	var doChange func(name string) error

	doChange = func(name string) error {
		if err := os.Chmod(name, mode); err != nil {
			return err
		}

		if !recursive {
			return nil
		}

		fi, err := os.Stat(name)
		if err != nil {
			return err
		}

		if !fi.IsDir() {
			return nil
		}

		dir, err := os.Open(name)
		if err != nil {
			return err
		}
		defer dir.Close()

		entries, err := dir.Readdirnames(0)
		if err != nil {
			return err
		}
		var firstErr error
		for _, entry := range entries {
			err := doChange(name + "/" + entry)
			if err != nil && firstErr == nil {
				firstErr = err
			}
		}
		return firstErr
	}

	return doChange(name)
}

func remove(path string, recursive bool) error {
	if recursive {
		return os.RemoveAll(path)
	}

	return os.Remove(path)
}

func rename(oldname, newname string) error {
	return os.Rename(oldname, newname)
}

func createDirectory(name string, recursive bool) error {
	if recursive {
		return os.MkdirAll(name, 0755)
	}

	return os.Mkdir(name, 0755)
}

type info struct {
	exists bool
	isDir  bool
}

// TODO: merge with FileEntry
func newInfo(file string) *info {
	fi, err := os.Stat(file)
	if err == nil {
		return &info{
			isDir:  fi.IsDir(),
			exists: true,
		}
	}

	if os.IsNotExist(err) {
		return &info{
			isDir:  false, // don't care
			exists: false,
		}
	}

	return nil
}

func cp(src, dst string) error {
	srcInfo, dstInfo := newInfo(src), newInfo(dst)

	// if the given path doesn't exist, there is nothing to be copied.
	if !srcInfo.exists {
		return fmt.Errorf("%s: no such file or directory.", src)
	}

	if !filepath.IsAbs(dst) || !filepath.IsAbs(src) {
		return errors.New("paths must be absolute.")
	}

	// cleanup paths before we continue. That means the followings will be equal:
	// "/home/arslan/" and "/home/arslan"
	src, dst = filepath.Clean(src), filepath.Clean(dst)

	// deny these cases:
	// "/home/arslan/Web" to "/home/arslan"
	// "/home/arslan"    to "/home/arslan"
	if src == dst || filepath.Dir(src) == dst {
		return fmt.Errorf("%s and %s are identical (not copied).", src, dst)
	}

	if srcInfo.isDir && dstInfo.exists {
		// deny this case:
		// "/home/arslan/Web" to "/home/arslan/server.go"
		if !dstInfo.isDir {
			return errors.New("can't copy a folder to a file")
		}

		// deny this case:
		// "/home/arslan" to "/home/arslan/Web"
		if strings.HasPrefix(dst, src) {
			return errors.New("cycle detected")
		}
	}

	srcBase, _ := filepath.Split(src)
	walks := 0

	// dstPath returns the rewritten destination path for the given source path
	dstPath := func(srcPath string) string {
		srcPath = strings.TrimPrefix(srcPath, srcBase)

		// foo/example/hello.txt -> bar/example/hello.txt
		if walks != 0 {
			return filepath.Join(dst, srcPath)
		}

		// hello.txt -> example/hello.txt
		if dstInfo.exists && dstInfo.isDir {
			return filepath.Join(dst, filepath.Base(srcPath))
		}

		// hello.txt -> test.txt
		return dst
	}

	return filepath.Walk(src, func(srcPath string, file os.FileInfo, err error) error {
		defer func() { walks++ }()

		if file.IsDir() {
			err := os.MkdirAll(dstPath(srcPath), 0755)
			if err != nil {
				fmt.Println("error 3", err)
				return errors.New("copy error [3]")
			}
		} else {
			err = copyFile(srcPath, dstPath(srcPath))
			if err != nil {
				fmt.Println("error 4", err)
				return errors.New("copy error [4]")
			}
		}

		return nil
	})
}

func copyFile(src, dst string) error {
	sf, err := os.Open(src)
	if err != nil {
		return err
	}
	defer sf.Close()

	fi, err := sf.Stat()
	if err != nil {
		return err
	}

	if fi.IsDir() {
		return errors.New("src is a directory, please provide a file")
	}

	df, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, fi.Mode())
	if err != nil {
		return err
	}
	defer df.Close()

	if _, err := io.Copy(df, sf); err != nil {
		return err
	}

	return nil
}
