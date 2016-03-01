package fusetest

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"testing"
)

func RunAllTests(t *testing.T, mountDir string) {
	// dir ops
	testMkDir(t, mountDir)
	testOpenDir(t, mountDir)
	testReadDir(t, mountDir)
	testRmDir(t, mountDir)
	testStatDir(t, mountDir)

	// file ops
	testCreateFile(t, mountDir)
	testOpenFile(t, mountDir)
	testReadFile(t, mountDir)
	testWriteFile(t, mountDir)

	// common ops
	testRename(t, mountDir)

	// git ops
	testGitClone(t, mountDir)
}

///// helpers

func createDir(mountDir, name string, fn func(string)) func() {
	return func() {
		dirPath := path.Join(mountDir, name)
		err := os.Mkdir(dirPath, 0705)
		if err != nil {
			panic(err)
		}

		fn(dirPath)

		err = os.RemoveAll(dirPath)
		if err != nil {
			panic(err)
		}
	}
}

func statDirCheck(dir string) (os.FileInfo, error) {
	fi, err := os.Stat(dir)
	if err != nil {
		return nil, err
	}

	if !fi.IsDir() {
		return nil, fmt.Errorf("Expected %s to be a dir.", dir)
	}

	return fi, nil
}

func statFileCheck(file string, mode os.FileMode) (os.FileInfo, error) {
	fi, err := os.Stat(file)
	if err != nil {
		return nil, err
	}

	if fi.IsDir() {
		return nil, fmt.Errorf("Expected %s to be not a dir.", file)
	}

	if fi.Mode() != mode {
		return nil, fmt.Errorf(
			"Expected %s to have mode %v, has mode %v", file, mode, fi.Mode(),
		)
	}

	return fi, nil
}

func readFile(filePath string, str string) error {
	d, err := ioutil.ReadFile(filePath)
	if err != nil {
		return err
	}

	if string(d) != str {
		return fmt.Errorf("Expected %s to equal %s.", str, d)
	}

	return nil
}

func readFileAt(fi *os.File, offset int64, str string) error {
	d := make([]byte, len(str))
	if _, err := fi.ReadAt(d, offset); err != nil {
		return err
	}

	if string(d) != str {
		return fmt.Errorf("Expected %s to equal %s.", str, d)
	}

	return nil
}
