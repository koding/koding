package fs

import (
	"errors"
	"fmt"
	"io"
	"io/ioutil"
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

func readDirectory(p string) ([]*FileEntry, error) {
	files, err := ioutil.ReadDir(p)
	if err != nil {
		return nil, err
	}

	ls := make([]*FileEntry, len(files))
	for i, info := range files {
		ls[i] = makeFileEntry(path.Join(p, info.Name()), info)
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

func readFile(path string) (map[string]interface{}, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	fi, err := file.Stat()
	if err != nil {
		return nil, err
	}

	if fi.Size() > 10*1024*1024 {
		return nil, fmt.Errorf("File larger than 10MiB.")
	}

	buf := make([]byte, fi.Size())
	if _, err := io.ReadFull(file, buf); err != nil {
		return nil, err
	}

	return map[string]interface{}{"content": buf}, nil
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
	entry := &FileEntry{
		Name:     fi.Name(),
		Exists:   true,
		FullPath: fullPath,
		IsDir:    fi.IsDir(),
		Size:     fi.Size(),
		Mode:     fi.Mode(),
		Time:     fi.ModTime(),
		Readable: isReadable(fi.Mode()),
		Writable: isWritable(fi.Mode()),
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

func isReadable(mode os.FileMode) bool { return mode&0400 != 0 }

func isWritable(mode os.FileMode) bool { return mode&0200 != 0 }

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
