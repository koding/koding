package fuseklient

import (
	"encoding/base64"
	"io/ioutil"
	"os"
	"path"
	"syscall"
	"testing"
	"time"

	"koding/fuseklient/transport"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	. "github.com/smartystreets/goconvey/convey"
)

func TestKodingNetworkFS(tt *testing.T) {
	Convey("fuse.FileSystem", tt, func() {
		Convey("It should implement all interface methods", func() {
			var _ fuseutil.FileSystem = (*KodingNetworkFS)(nil)
		})

		Convey("It should mount and unmount a directory", func() {
			k := newknfs(nil)

			_, err := k.Mount()
			So(err, ShouldBeNil)

			So(_unmount(k), ShouldBeNil)
		})
	})

	Convey("Given mounted directory", tt, func() {
		k := newknfs(nil)

		_, err := k.Mount()
		So(err, ShouldBeNil)

		statDirectoryCheck := func(dir string) {
			fi, err := os.Stat(dir)
			So(err, ShouldBeNil)

			So(fi.IsDir(), ShouldBeTrue)
			So(fi.Mode(), ShouldEqual, 0700|os.ModeDir)
		}

		statFileCheck := func(filePath string, mode os.FileMode) {
			fi, err := os.Stat(filePath)
			So(err, ShouldBeNil)

			So(fi.IsDir(), ShouldBeFalse)
			So(fi.Mode(), ShouldEqual, mode)
		}

		readFile := func(filePath string, str string) {
			bytes, err := ioutil.ReadFile(filePath)
			So(err, ShouldBeNil)
			So(string(bytes), ShouldEqual, str)
		}

		readFileAt := func(fi *os.File, offset int64, str string) {
			dst := make([]byte, len(str))

			n, err := fi.ReadAt(dst, offset)
			So(err, ShouldBeNil)
			So(string(dst), ShouldEqual, str)
			So(n, ShouldEqual, len(str))
		}

		filePath := path.Join(k.MountPath, "file")
		err = ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
		So(err, ShouldBeNil)

		Convey("GetInodeAttributes", func() {
			Convey("It should return root directory attributes", func() {
				statDirectoryCheck(k.MountPath)
			})

			Convey("It should return existing file attributes", func() {
				filePath := path.Join(k.MountPath, "file")

				statFileCheck(filePath, 0700)
			})

			Convey("It should return newly created file attributes", func() {
				filePath := path.Join(k.MountPath, "newfile")

				err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
				So(err, ShouldBeNil)

				statFileCheck(filePath, 0700)
			})

			Convey("It should return newly created nested directory attributes", func() {
				directoryPath := path.Join(k.MountPath, "1", "2")

				err := os.MkdirAll(directoryPath, 0700)
				So(err, ShouldBeNil)

				statDirectoryCheck(directoryPath)
			})
		})

		Convey("OpenDir", func() {
			Convey("It should open root directory", func() {
				dir, err := os.Open(k.MountPath)
				So(err, ShouldBeNil)

				So(dir.Name(), ShouldEqual, k.MountPath)

				statDirectoryCheck(k.MountPath)
			})

			Convey("It should open newly created nested directory", func() {
				directoryPath := path.Join(k.MountPath, "1", "2")

				err := os.MkdirAll(directoryPath, 0700)
				So(err, ShouldBeNil)

				dir, err := os.Open(directoryPath)
				So(err, ShouldBeNil)

				So(dir.Name(), ShouldEqual, directoryPath)

				statDirectoryCheck(directoryPath)
			})
		})

		Convey("ReadDir", func() {
			files, err := ioutil.ReadDir(k.MountPath)
			So(err, ShouldBeNil)

			Convey("It should return entries", func() {
				fi, err := os.Stat(k.MountPath)
				So(err, ShouldBeNil)

				So(fi.IsDir(), ShouldBeTrue)
				So(fi.Mode(), ShouldEqual, 0700|os.ModeDir)

				So(len(files), ShouldEqual, 1)
				So(files[0].Name(), ShouldEqual, "file")

				Convey("It should not return ignored entries", func() {
					So(files[0].Name(), ShouldNotEqual, "node_modules")
				})
			})
		})

		Convey("Mkdir", func() {
			Convey("It should create directory inside mounted directory", func() {
				directoryPath := path.Join(k.MountPath, "directory")

				So(os.Mkdir(directoryPath, 0700), ShouldBeNil)
				statDirectoryCheck(directoryPath)

				Convey("It should create directory inside newly created directory recursively", func() {
					So(os.MkdirAll(path.Join(directoryPath, "1", "2"), 0700), ShouldBeNil)

					statDirectoryCheck(path.Join(directoryPath, "1"))
					statDirectoryCheck(path.Join(directoryPath, "1", "2"))
				})
			})

			Convey("It should create with given permissions", func() {
				directoryPath := path.Join(k.MountPath, "directory")

				err := os.MkdirAll(directoryPath, 0705)
				So(err, ShouldBeNil)

				fi, err := os.Stat(directoryPath)
				So(err, ShouldBeNil)

				So(fi.IsDir(), ShouldBeTrue)
				So(fi.Mode(), ShouldEqual, 0705|os.ModeDir)
			})

			Convey("It should return err when creating already existing directory", func() {
				directoryPath := path.Join(k.MountPath, "directory")

				err := os.Mkdir(directoryPath, 0700)
				So(err, ShouldBeNil)

				err = os.Mkdir(directoryPath, 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "exists")
			})

			Convey("It should return err when creating directory inside a file", func() {
				directoryPath := path.Join(k.MountPath, "file", "directory")

				err := os.Mkdir(directoryPath, 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "not a directory")
			})

			Convey("It should return err when creating directory inside a nonexistend directory", func() {
				directoryPath := path.Join(k.MountPath, "nonexistent", "directory")

				err := os.Mkdir(directoryPath, 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")
			})

			Convey("It should return err when creating directory inside unpermitted directory", func() {
				path1 := path.Join(k.MountPath, "notpermitted")
				So(os.Mkdir(path1, 0500), ShouldBeNil)

				path2 := path.Join(k.MountPath, "notpermitted", "directory")
				err := os.Mkdir(path2, 0700)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "permission denied")
			})
		})

		Convey("Rename", func() {
			Convey("It should rename newly created directory", func() {
				oldPath := path.Join(k.MountPath, "oldpath")
				newPath := path.Join(k.MountPath, "newpath")

				// create directory mount/oldpath/
				err := os.Mkdir(oldPath, 0700)
				So(err, ShouldBeNil)

				// rename mount/oldPath/ to mount/newpath/
				err = os.Rename(oldPath, newPath)
				So(err, ShouldBeNil)

				// check mount/oldPath/ doesn't exist
				_, err = os.Stat(oldPath)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")

				// check mount/newPath/ exists
				statDirectoryCheck(newPath)

				// TODO: add newpath to fakeTransport#TripResponses
				// statDirectoryCheck(newPath)
			})

			Convey("It should rename existing file", func() {
				oldPath := path.Join(k.MountPath, "file")
				newPath := path.Join(k.MountPath, "renamedfile")

				// rename mount/file to mount/renamedfile
				err = os.Rename(oldPath, newPath)
				So(err, ShouldBeNil)

				// check mount/file doesn't exist
				_, err = os.Stat(oldPath)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")

				// check mount/renamedfile exists
				statFileCheck(newPath, 0700)

				Convey("It should set new file size to be same as old file", func() {
					fi, err := os.Stat(newPath)
					So(err, ShouldBeNil)
					So(fi.Size(), ShouldEqual, 12) // size of content
				})

				Convey("It should new file content to be same as old file", func() {
					bytes, err := ioutil.ReadFile(newPath)
					So(err, ShouldBeNil)
					So(string(bytes), ShouldEqual, "Hello World!")
				})
			})

			Convey("It should rename newly created file", func() {
				oldPath := path.Join(k.MountPath, "oldfile")
				err := ioutil.WriteFile(oldPath, []byte("Hello World!"), 0700)
				So(err, ShouldBeNil)

				readFile(oldPath, "Hello World!")

				// rename mount/oldfile to mount/newfile
				newPath := path.Join(k.MountPath, "newfile")
				err = os.Rename(oldPath, newPath)
				So(err, ShouldBeNil)

				// check mount/oldfile doesn't exist
				_, err = os.Stat(oldPath)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")

				// check mount/newfile exists with same permissions
				statFileCheck(newPath, 0700)

				Convey("It should new file size to be same as old file", func() {
					fi, err := os.Stat(newPath)
					So(err, ShouldBeNil)
					So(fi.Size(), ShouldEqual, 12) // size of content
				})

				Convey("It should new file content to be same as old file", func() {
					bytes, err := ioutil.ReadFile(newPath)
					So(err, ShouldBeNil)
					So(string(bytes), ShouldEqual, "Hello World!")
				})
			})

			Convey("It should rename file to existing file", func() {
				file1 := path.Join(k.MountPath, "file1")
				err := ioutil.WriteFile(file1, []byte("Hello"), 0700)
				So(err, ShouldBeNil)

				file2 := path.Join(k.MountPath, "file2")
				err = ioutil.WriteFile(file2, []byte("World!"), 0700)
				So(err, ShouldBeNil)

				// rename mount/file2 to mount/file1
				err = os.Rename(file2, file1)
				So(err, ShouldBeNil)

				// check mount/file2 doesn't exist
				_, err = os.Stat(file2)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")

				// check mount/file1 exists with same permissions
				statFileCheck(file1, 0700)

				readFile(file1, "World!")
			})
		})

		Convey("RmDir", func() {
			Convey("It should remove directory in root directory", func() {
				directoryPath := path.Join(k.MountPath, "1")

				// create directory mount/1/
				err := os.Mkdir(directoryPath, 0700)
				So(err, ShouldBeNil)

				// remove directory mount/1/2
				err = os.Remove(directoryPath)
				So(err, ShouldBeNil)
			})

			Convey("It should remove directory in another directory", func() {
				directoryPath1 := path.Join(k.MountPath, "1")
				directoryPath2 := path.Join(k.MountPath, "1", "2")

				// create nested directory mount/1/2/
				err := os.MkdirAll(directoryPath2, 0700)
				So(err, ShouldBeNil)

				// remove directory mount/1/2/
				err = os.Remove(directoryPath2)
				So(err, ShouldBeNil)

				// check mount/1/2/ doesn't exist
				_, err = os.Stat(directoryPath2)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")

				// check mount/1/ still exists
				_, err = os.Stat(directoryPath1)
				So(err, ShouldBeNil)
			})

			Convey("It should remove all entries inside specified directory", func() {
				directoryPath1 := path.Join(k.MountPath, "1")
				directoryPath2 := path.Join(k.MountPath, "1", "2")

				// create nested directories mount/1/2/
				err := os.MkdirAll(directoryPath2, 0700)
				So(err, ShouldBeNil)

				// create file in under mount/1/
				filePath := path.Join(directoryPath1, "file")
				err = ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
				So(err, ShouldBeNil)

				// delete directory mount/1/
				err = os.RemoveAll(directoryPath1)
				So(err, ShouldBeNil)

				// check mount/1/2/ doesn't exist
				_, err = os.Stat(directoryPath2)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")

				// check mount/1/ doesn't exist
				_, err = os.Stat(directoryPath1)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")

				// check mount/1/file doesn't exist
				_, err = os.Stat(filePath)
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "no such file or directory")
			})
		})

		Convey("OpenFile", func() {
			Convey("It should return err when trying to open nonexistent file", func() {
				fileName := path.Join(k.MountPath, "nonexistent")
				_, err := os.OpenFile(fileName, os.O_WRONLY, 0400)
				So(err, ShouldNotBeNil)
			})

			Convey("It should open file in root directory", func() {
				fileName := path.Join(k.MountPath, "file")
				fi, err := os.OpenFile(fileName, os.O_WRONLY, 0400)
				So(err, ShouldBeNil)

				Convey("It should set file properties", func() {
					st, err := fi.Stat()
					So(err, ShouldBeNil)

					// Get the time difference between when the file was created, and
					// when this specific test was run.
					fileCreatedAgo := time.Now().UTC().Sub(st.ModTime().UTC())

					So(st.IsDir(), ShouldEqual, false)
					So(st.Name(), ShouldEqual, "file")
					So(st.Size(), ShouldEqual, 12)
					// Check if the diff was small. Within 5 seconds, to account for
					// any laggy/blocking tests..
					So(fileCreatedAgo, ShouldAlmostEqual, 0, 5*time.Second)
				})

				Convey("It should save entry with handleId", func() {
					So(len(k.liveHandles), ShouldEqual, 1)
				})
			})
		})

		Convey("ReadFile", func() {
			Convey("It should read an existing file in root directory", func() {
				filePath := path.Join(k.MountPath, "file")

				readFile(filePath, "Hello World!")

				fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
				So(err, ShouldBeNil)

				dst := make([]byte, 12) // size of string
				n, err := fi.Read(dst)
				So(err, ShouldBeNil)
				So(string(dst), ShouldEqual, "Hello World!")
				So(n, ShouldEqual, 12) // size of string

				Convey("It should read file with specified offset: 0", func() {
					readFileAt(fi, 0, "Hello World!")
				})

				Convey("It should read with specified offset: 4", func() {
					readFileAt(fi, 6, "World!")
				})
			})

			Convey("It should read a newly created file in root directory", func() {
				filePath := path.Join(k.MountPath, "newfile")
				err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
				So(err, ShouldBeNil)

				readFile(filePath, "Hello World!")

				fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
				So(err, ShouldBeNil)

				Convey("It should read file with specified offset: 0", func() {
					readFileAt(fi, 0, "Hello World!")
				})

				Convey("It should read with specified offset: 4", func() {
					readFileAt(fi, 6, "World!")
				})
			})

			Convey("It should read a new file inside newly created deeply nested directory", func() {
				directoryPath := path.Join(k.MountPath, "1", "2")
				So(os.MkdirAll(directoryPath, 0700), ShouldBeNil)

				filePath := path.Join(directoryPath, "newfile")
				err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
				So(err, ShouldBeNil)

				readFile(filePath, "Hello World!")

				fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
				So(err, ShouldBeNil)

				Convey("It should read file with specified offset: 0", func() {
					readFileAt(fi, 0, "Hello World!")
				})

				Convey("It should read with specified offset: 4", func() {
					readFileAt(fi, 6, "World!")
				})
			})
		})

		Convey("CreateFile", func() {
			Convey("It should create a new file in root directory", func() {
				filePath := path.Join(k.MountPath, "newfile")
				err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0500)
				So(err, ShouldBeNil)

				statFileCheck(filePath, 0500)
			})

			Convey("It should create a new file inside newly created deeply nested directory", func() {
				directoryPath := path.Join(k.MountPath, "directory1", "directory2")
				So(os.MkdirAll(directoryPath, 0700), ShouldBeNil)

				fileCreated := time.Now()
				filePath := path.Join(directoryPath, "file")
				err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
				So(err, ShouldBeNil)

				Convey("It should set file properties", func() {
					fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
					So(err, ShouldBeNil)

					st, err := fi.Stat()
					So(err, ShouldBeNil)

					So(st.IsDir(), ShouldEqual, false)
					So(st.ModTime().UTC(), ShouldHappenAfter, fileCreated)
					So(st.Name(), ShouldEqual, "file")
					So(st.Size(), ShouldEqual, 12)
				})
			})
		})

		Convey("WriteFile", func() {
			Convey("It should return error when trying to modify file with wrong flag", func() {
				filePath := path.Join(k.MountPath, "file")

				fi, err := os.OpenFile(filePath, os.O_RDONLY, 0755)
				So(err, ShouldBeNil)

				_, err = fi.Write([]byte{})
				So(err, ShouldNotBeNil)
				So(err.Error(), ShouldContainSubstring, "bad file descriptor")
			})

			Convey("It should modify an existing file in root directory", func() {
				filePath := path.Join(k.MountPath, "file")

				fi, err := os.OpenFile(filePath, os.O_WRONLY, 0755)
				So(err, ShouldBeNil)

				newContent := []byte("This file has been modified!")
				bytes, err := fi.Write(newContent)
				So(err, ShouldBeNil)
				So(bytes, ShouldEqual, len(newContent))
			})

			Convey("It should modify a newly created file in root directory", func() {
				filePath := path.Join(k.MountPath, "file1")

				err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
				So(err, ShouldBeNil)

				fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
				So(err, ShouldBeNil)

				newContent := []byte("This file has been modified!")
				bytes, err := fi.Write(newContent)
				So(err, ShouldBeNil)
				So(bytes, ShouldEqual, len(newContent))

				readFile(filePath, string(newContent))
			})

			Convey("It should modify a new file inside newly created deeply nested directory", func() {
				directoryPath := path.Join(k.MountPath, "1", "2")
				So(os.MkdirAll(directoryPath, 0700), ShouldBeNil)

				filePath := path.Join(directoryPath, "file")

				err := ioutil.WriteFile(filePath, []byte("Hello World!"), 0700)
				So(err, ShouldBeNil)

				fi, err := os.OpenFile(filePath, os.O_WRONLY, 0500)
				So(err, ShouldBeNil)

				newContent := []byte("This file has been modified!")
				bytes, err := fi.Write(newContent)
				So(err, ShouldBeNil)
				So(bytes, ShouldEqual, len(newContent))

				readFile(filePath, string(newContent))
			})
		})

		Convey("StatFS", func() {
			localFs := syscall.Statfs_t{}
			err := syscall.Statfs("/", &localFs)
			So(err, ShouldBeNil)

			mountFs := syscall.Statfs_t{}
			err = syscall.Statfs(k.MountPath, &mountFs)
			So(err, ShouldBeNil)

			// Because blocks free can differ, due to creating files/etc,
			// we check for the blocks free differing by up to 1%. This may
			// need to be larger if Wercker/etc are installing libraries while
			// these tests are running.. but normal conditions should be fine.
			allowedBfreeDiff := float64(localFs.Bfree) * 0.01

			So(mountFs.Bsize, ShouldEqual, localFs.Bsize)
			So(mountFs.Blocks, ShouldAlmostEqual, localFs.Blocks)
			So(mountFs.Bfree, ShouldAlmostEqual, localFs.Bfree, allowedBfreeDiff)
		})

		Convey("ReleaseFileHandle", func() {
			fileName := path.Join(k.MountPath, "file")
			fi, err := os.OpenFile(fileName, os.O_RDONLY, 0400)
			So(err, ShouldBeNil)

			// find File from list of nodes, so we can compare it later
			var file *File
			for _, f := range k.liveNodes {
				possibleFile, ok := f.(*File)
				if ok && possibleFile.Name == "file" {
					file = possibleFile
				}
			}

			if file == nil {
				tt.Fatalf("File instance not found in list of nodes")
			}

			file.Content = []byte("Hello World!")

			// sanity check to make sure file is saved to handle list when opened
			So(len(k.liveHandles), ShouldEqual, 1)

			err = fi.Close()
			So(err, ShouldBeNil)

			Convey("It should delete file from handle list when released", func() {
				So(len(k.liveHandles), ShouldEqual, 0)
			})

			Convey("It should set file content to nil", func() {
				So(len(file.Content), ShouldEqual, 0)
			})
		})

		//Convey("LookUpInode", func() {
		//})

		// Convey("SetInodeAttributes", func() {
		// })

		// Convey("FlushFile", func() {
		// })

		// Convey("SyncFile", func() {
		// })

		// Convey("Unlink", func() {
		// })

		defer _unmount(k)
	})
}

func TestKodingNetworkFSUnit(tt *testing.T) {
	i := fuseops.InodeID(fuseops.RootInodeID + 1)
	var t transport.Transport

	// Convey("NewKodingNetworkFS", t, func() {
	// })

	Convey("KodingNetworkFS#getDir", tt, func() {
		Convey("It should return error if specified id is not a directory", func() {
			k := newknfs(t)
			k.liveNodes[i] = newFile()

			_, err := k.getDir(i)
			So(err, ShouldEqual, fuse.EIO)
		})

		Convey("It should return directory with specified id", func() {
			k := newknfs(t)
			k.liveNodes[i] = newDir()

			dir, err := k.getDir(i)
			So(err, ShouldBeNil)
			So(dir, ShouldHaveSameTypeAs, &Dir{})
		})
	})

	Convey("KodingNetworkFS#getFile", tt, func() {
		Convey("It should return error if specified id is not a file", func() {
			k := newknfs(t)
			k.liveNodes[i] = newDir()

			_, err := k.getFile(i)
			So(err, ShouldEqual, fuse.EIO)
		})

		Convey("It should return file with specified id", func() {
			k := newknfs(t)
			k.liveNodes[i] = newFile()

			file, err := k.getEntry(i)
			So(err, ShouldBeNil)
			So(file, ShouldHaveSameTypeAs, &File{})
		})
	})

	Convey("KodingNetworkFS#getEntry", tt, func() {
		Convey("It should return error if specified id doesn't exit", func() {
			k := newknfs(t)
			_, err := k.getEntry(i)
			So(err, ShouldEqual, fuse.ENOENT)
		})

		Convey("It should return entry with specified id", func() {
			k := newknfs(t)
			k.liveNodes[i] = newDir()

			_, err := k.getEntry(i)
			So(err, ShouldBeNil)
		})
	})

	Convey("KodingNetworkFS#setEntry", tt, func() {
		k := newknfs(t)
		d := newDir()

		k.setEntry(d.GetID(), d)

		So(len(k.liveNodes), ShouldEqual, 2)
		dir, ok := k.liveNodes[i]
		So(ok, ShouldBeTrue)
		So(d, ShouldEqual, dir)
	})

	Convey("KodingNetworkFS#deleteEntry", tt, func() {
		k := newknfs(t)
		k.liveNodes[i] = newDir()

		k.deleteEntry(i)

		So(len(k.liveNodes), ShouldEqual, 1)
		_, ok := k.liveNodes[i]
		So(ok, ShouldBeFalse)
	})
}

func TestKodingNetworkFSHandles(tt *testing.T) {
	Convey("", tt, func() {
		k := newknfs(nil)
		d := newDir()
		f := newFile()

		Convey("It should save generate id for entry", func() {
			handleId := k.setEntryByHandle(d)
			So(handleId, ShouldEqual, 1)
		})

		Convey("It should save entry", func() {
			handleId := k.setEntryByHandle(d)

			node, ok := k.liveHandles[handleId]
			So(ok, ShouldBeTrue)
			So(node.GetID(), ShouldEqual, d.GetID())
		})

		Convey("It should get entry with handle id", func() {
			handleId := k.setEntryByHandle(d)

			node, err := k.getByHandle(handleId)
			So(err, ShouldBeNil)
			So(node.GetID(), ShouldEqual, d.GetID())
		})

		Convey("It should get dir with handle id", func() {
			handleId := k.setEntryByHandle(d)

			savedDir, err := k.getDirByHandle(handleId)
			So(err, ShouldBeNil)
			So(savedDir.GetType(), ShouldEqual, fuseutil.DT_Directory)
		})

		Convey("It should get file with handle id", func() {
			handleId := k.setEntryByHandle(f)

			savedFile, err := k.getFileByHandle(handleId)
			So(err, ShouldBeNil)
			So(savedFile.GetType(), ShouldEqual, fuseutil.DT_File)
		})

		Convey("It should delete file with handle id", func() {
			handleId := k.setEntryByHandle(f)

			k.deleteEntryByHandle(handleId)

			_, err := k.getFileByHandle(handleId)
			So(err, ShouldEqual, fuse.ENOENT)
		})
	})
}

func _unmount(k *KodingNetworkFS) error {
	if err := k.Unmount(); err != nil {
		return err
	}

	return os.RemoveAll(k.MountPath)
}

// newknfs creates a new KodingNetworkFS setup for testing. If the transport
// argument is nil, a remote transport is automatically setup.
func newknfs(t transport.Transport) *KodingNetworkFS {
	mountDir, err := ioutil.TempDir("", "mounttest")
	if err != nil {
		panic(err)
	}

	if t == nil {
		remoteDir, err := ioutil.TempDir("", "mounttest_remote")
		if err != nil {
			panic(err)
		}

		client, err := newKlientClient()
		if err != nil {
			panic(err)
		}

		t = &transport.RemoteTransport{
			Client:      client,
			RemotePath:  remoteDir,
			TellTimeout: 4 * time.Second,
		}
	}

	c := &Config{
		Path:           mountDir,
		NoPrefetchMeta: true,
		NoWatch:        true,
	}
	k, err := NewKodingNetworkFS(t, c)
	if err != nil {
		panic(err)
	}

	return k
}
