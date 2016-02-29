package fusetest

import (
	"fmt"
	"io/ioutil"
	"os"
	"path"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
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
}

func testMkDir(t *testing.T, mountDir string) {
	Convey("Mkdir", t, func() {
		Convey("It should create dir inside mount", func() {
			dirPath := path.Join(mountDir, "MkDir")
			So(os.Mkdir(dirPath, 0705), ShouldBeNil)

			Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

			fi, err := statDirCheck(dirPath)
			So(err, ShouldBeNil)

			So(fi.Name(), ShouldEqual, "MkDir")

			Convey("It should create nested dir inside new dir", func() {
				// create /MkDir/dir1
				nestedPath := path.Join(dirPath, "dir1")
				So(os.Mkdir(nestedPath, 0700), ShouldBeNil)

				fi, err := statDirCheck(dirPath)
				So(err, ShouldBeNil)

				So(fi.Name(), ShouldEqual, "MkDir")
			})

			Convey("It should create with given permissions", func() {
				fi, err := os.Stat(dirPath)
				So(err, ShouldBeNil)

				So(fi.IsDir(), ShouldBeTrue)
				So(fi.Mode(), ShouldEqual, 0705|os.ModeDir)
			})

			Convey("It should return err when creating already existing dir", func() {
				err = os.Mkdir(dirPath, 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "exists")
			})

			Convey("It should return err when creating dir inside a file", func() {
				filePath := path.Join(dirPath, "file1")

				_, err := os.Create(filePath)
				So(err, ShouldBeNil)

				err = os.Mkdir(path.Join(filePath, "dir1"), 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "not a directory")
			})

			Convey("It should return err when creating dir inside a nonexistent dir", func() {
				path1 := path.Join(dirPath, "dir1", "dir2")

				err := os.Mkdir(path1, 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")
			})

			Convey("It should return err when creating dir inside unpermitted dir", func() {
				path1 := path.Join(dirPath, "dir1")
				So(os.Mkdir(path1, 0500), ShouldBeNil)

				path2 := path.Join(path1, "dir2")
				err := os.Mkdir(path2, 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "permission denied")
			})
		})
	})
}

func testOpenDir(t *testing.T, mountDir string) {
	Convey("OpenDir", t, func() {
		dir, err := os.Open(mountDir)

		Convey("It should open root dir", func() {
			So(err, ShouldBeNil)

			_, err := statDirCheck(mountDir)
			So(err, ShouldBeNil)

			Convey("It should return dir name", func() {
				So(dir.Name(), ShouldEqual, mountDir)
			})
		})

		Convey("It should open newly created nested dir", func() {
			dirPath := path.Join(mountDir, "OpenDir", "dir1")

			So(os.MkdirAll(dirPath, 0700), ShouldBeNil)
			Reset(func() { So(os.RemoveAll(path.Dir(dirPath)), ShouldBeNil) })

			dir, err := os.Open(dirPath)
			So(err, ShouldBeNil)

			_, err = statDirCheck(dirPath)
			So(err, ShouldBeNil)

			Convey("It should return dir name", func() {
				So(dir.Name(), ShouldEqual, dirPath)
			})

		})

		Convey("It should close dir", func() {
			So(dir.Close(), ShouldBeNil)
		})
	})
}

func testReadDir(t *testing.T, mountDir string) {
	Convey("ReadDir", t, func() {
		dirPath := path.Join(mountDir, "ReadDir", "dir1")
		So(os.MkdirAll(dirPath, 0700), ShouldBeNil)

		Reset(func() { So(os.RemoveAll(path.Dir(dirPath)), ShouldBeNil) })

		filePath := path.Join(mountDir, "ReadDir", "file1")
		_, err := os.Create(filePath)
		So(err, ShouldBeNil)

		Convey("It should return entries of dir", func() {
			entries, err := ioutil.ReadDir(path.Join(mountDir, "ReadDir"))
			So(err, ShouldBeNil)

			So(len(entries), ShouldEqual, 2)

			// lexical ordering should ensure dir1 will always return before file1
			So(entries[0].Name(), ShouldEqual, "dir1")
			So(entries[1].Name(), ShouldEqual, "file1")
		})
	})
}

func testRmDir(t *testing.T, mountDir string) {
	Convey("RmDir", t, func() {
		dirPath := path.Join(mountDir, "RmDir")
		nestedDir := path.Join(dirPath, "dir1")

		So(os.MkdirAll(nestedDir, 0705), ShouldBeNil)

		Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

		Convey("It should remove directory in root dir", func() {
			So(os.RemoveAll(dirPath), ShouldBeNil)
		})

		Convey("It should remove all entries inside specified directory", func() {
			dirPath2 := path.Join(nestedDir, "dir2")

			So(os.MkdirAll(dirPath2, 0700), ShouldBeNil)

			filePath := path.Join(nestedDir, "file")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			err = os.RemoveAll(nestedDir)
			So(err, ShouldBeNil)

			_, err = os.Stat(dirPath2)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			_, err = os.Stat(nestedDir)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			_, err = os.Stat(filePath)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")
		})
	})
}

func testOpenFile(t *testing.T, mountDir string) {
	Convey("OpenFile", t, func() {
		dirPath := path.Join(mountDir, "OpenFile")
		So(os.Mkdir(dirPath, 0705), ShouldBeNil)

		Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

		Convey("It should return err when trying to open nonexistent file", func() {
			filePath := path.Join(mountDir, "nonexistent")
			_, err := os.OpenFile(filePath, os.O_WRONLY, 0400)
			So(err, ShouldNotBeNil)
		})

		Convey("It should open file in root directory", func() {
			filePath := path.Join(dirPath, "file")

			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_WRONLY, 0400)
			So(err, ShouldBeNil)

			Convey("It should return file properties", func() {
				st, err := fi.Stat()
				So(err, ShouldBeNil)

				// Get the time difference between when the file was created, and
				// when this specific test was run.
				fileCreatedAgo := time.Now().UTC().Sub(st.ModTime().UTC())

				So(st.IsDir(), ShouldEqual, false)
				So(st.Name(), ShouldEqual, "file")
				So(st.Size(), ShouldEqual, 12)

				// Check if the diff was small. Within 1 seconds, to account for
				// any laggy/blocking tests..
				So(fileCreatedAgo, ShouldAlmostEqual, 0, 1*time.Second)
			})
		})
	})
}

func testReadFile(t *testing.T, mountDir string) {
	Convey("ReadFile", t, func() {
		dirPath := path.Join(mountDir, "ReadFile")
		So(os.Mkdir(dirPath, 0705), ShouldBeNil)

		Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

		filePath := path.Join(dirPath, "nonexistent")
		err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Convey("It should read an existing file in root directory", func() {
			So(readFile(filePath, "Hello World!"), ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
			So(err, ShouldBeNil)

			dst := make([]byte, 12) // size of string
			n, err := fi.Read(dst)
			So(err, ShouldBeNil)
			So(string(dst), ShouldEqual, "Hello World!")
			So(n, ShouldEqual, 12) // size of string

			Convey("It should read file with specified offset: 0", func() {
				So(readFileAt(fi, 0, "Hello World!"), ShouldBeNil)
			})

			Convey("It should read with specified offset: 4", func() {
				So(readFileAt(fi, 6, "World!"), ShouldBeNil)
			})
		})

		Convey("It should read a new file inside newly created deeply nested directory", func() {
			nestedDirPath := path.Join(dirPath, "nested")
			So(os.Mkdir(nestedDirPath, 0700), ShouldBeNil)

			filePath := path.Join(nestedDirPath, "file1")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			So(readFile(filePath, "Hello World!"), ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
			So(err, ShouldBeNil)

			Convey("It should read file with specified offset: 0", func() {
				So(readFileAt(fi, 0, "Hello World!"), ShouldBeNil)
			})

			Convey("It should read with specified offset: 4", func() {
				So(readFileAt(fi, 6, "World!"), ShouldBeNil)
			})
		})
	})
}

func testStatDir(t *testing.T, mountDir string) {
	Convey("It should return dir info", t, func() {
		fi, err := statDirCheck(mountDir)
		So(err, ShouldBeNil)

		So(fi.Name(), ShouldEqual, path.Base(mountDir))
	})
}

func testCreateFile(t *testing.T, mountDir string) {
	Convey("CreateFile", t, func() {
		dirPath := path.Join(mountDir, "CreateFile")
		So(os.Mkdir(dirPath, 0705), ShouldBeNil)

		Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

		Convey("It should create a new file in root directory", func() {
			filePath := path.Join(dirPath, "newfile")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
			So(err, ShouldBeNil)

			_, err = statFileCheck(filePath, 0500)
			So(err, ShouldBeNil)
		})

		Convey("It should create a new file inside newly created deeply nested directory", func() {
			dirPath1 := path.Join(dirPath, "dir1")
			So(os.MkdirAll(dirPath1, 0700), ShouldBeNil)

			filePath := path.Join(dirPath1, "file")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			Convey("It should return file properties", func() {
				fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
				So(err, ShouldBeNil)

				st, err := fi.Stat()
				So(err, ShouldBeNil)

				So(st.IsDir(), ShouldEqual, false)
				So(st.Name(), ShouldEqual, "file")
				So(st.Size(), ShouldEqual, 12)
			})
		})
	})
}

func testWriteFile(t *testing.T, mountDir string) {
	Convey("WriteFile", t, func() {
		dirPath := path.Join(mountDir, "WriteFile")
		So(os.Mkdir(dirPath, 0705), ShouldBeNil)

		filePath := path.Join(dirPath, "file")
		err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

		Convey("It should return error when trying to modify file with wrong flag", func() {

			fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
			So(err, ShouldBeNil)

			_, err = fi.Write([]byte{})
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "bad file descriptor")
		})

		Convey("It should write content to existing file in root directory", func() {
			fi, err := os.OpenFile(filePath, os.O_WRONLY, 0755)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!")
			bytes, err := fi.Write(newContent)
			So(err, ShouldBeNil)
			So(bytes, ShouldEqual, len(newContent))
		})

		Convey("It should modify a new file inside newly created deeply nested directory", func() {
			dirPath := path.Join(dirPath, "dir1")
			So(os.Mkdir(dirPath, 0705), ShouldBeNil)

			filePath := path.Join(dirPath, "file1")
			err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
			So(err, ShouldBeNil)

			newContent := []byte("This file has been modified!")
			bytes, err := fi.Write(newContent)
			So(err, ShouldBeNil)
			So(bytes, ShouldEqual, len(newContent))

			So(readFile(filePath, string(newContent)), ShouldBeNil)
		})
	})
}

func testRename(t *testing.T, mountDir string) {
	Convey("Rename", t, func() {
		dirPath := path.Join(mountDir, "Rename")
		So(os.Mkdir(dirPath, 0705), ShouldBeNil)

		Reset(func() { So(os.RemoveAll(dirPath), ShouldBeNil) })

		Convey("It should rename dir", func() {
			oldPath := path.Join(dirPath, "oldpath")
			newPath := path.Join(dirPath, "newpath")

			So(os.Mkdir(oldPath, 0700), ShouldBeNil)

			So(os.Rename(oldPath, newPath), ShouldBeNil)

			_, err := os.Stat(oldPath)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			statDirCheck(newPath)
		})

		Convey("It should rename file", func() {
			oldPath := path.Join(dirPath, "file")
			newPath := path.Join(dirPath, "renamedfile")

			err := ioutil.WriteFile(oldPath, []byte("Hello World!"), 0700)
			So(err, ShouldBeNil)

			fi, err := statFileCheck(oldPath, 0700)
			So(err, ShouldBeNil)

			So(os.Rename(oldPath, newPath), ShouldBeNil)

			_, err = os.Stat(oldPath)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			fi, err = statFileCheck(newPath, 0700)
			So(err, ShouldBeNil)

			Convey("It should set new file size to be same as old file", func() {
				So(fi.Size(), ShouldEqual, 12) // size of content
			})

			Convey("It should new file content to be same as old file", func() {
				bytes, err := ioutil.ReadFile(newPath)
				So(err, ShouldBeNil)
				So(string(bytes), ShouldEqual, "Hello World!")
			})
		})

		Convey("It should rename file to existing file", func() {
			file1 := path.Join(dirPath, "file1")
			err := ioutil.WriteFile(file1, []byte("Hello"), 0700)
			So(err, ShouldBeNil)

			file2 := path.Join(mountDir, "file2")
			err = ioutil.WriteFile(file2, []byte("World!"), 0700)
			So(err, ShouldBeNil)

			err = os.Rename(file2, file1)
			So(err, ShouldBeNil)

			_, err = os.Stat(file2)
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "no such file or directory")

			_, err = statFileCheck(file1, 0700)
			So(err, ShouldBeNil)

			So(readFile(file1, "World!"), ShouldBeNil)
		})
	})
}

///// helpers

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
