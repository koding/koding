package fuseklient

import (
	"io/ioutil"
	"os"
	"path"
	"syscall"
	"testing"
	"time"

	"golang.org/x/net/context"

	"koding/fuseklient/transport"
	"koding/fusetest"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
	. "github.com/smartystreets/goconvey/convey"
)

func TestKodingNetworkFS1(t *testing.T) {
	k := newknfs(nil)
	if _, err := k.Mount(); err != nil {
		t.Fatal(err)
	}

	defer _unmount(k)

	fusetest.RunAllTests(t, k.MountPath)
}

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

	ctx := context.TODO()

	Convey("KodingNetworkFS#getDir", tt, func() {
		Convey("It should return error if specified id is not a directory", func() {
			k := newknfs(t)
			k.liveNodes[i] = newFile()

			_, err := k.getDir(ctx, i)
			So(err, ShouldEqual, fuse.EIO)
		})

		Convey("It should return directory with specified id", func() {
			k := newknfs(t)
			k.liveNodes[i] = newDir()

			dir, err := k.getDir(ctx, i)
			So(err, ShouldBeNil)
			So(dir, ShouldHaveSameTypeAs, &Dir{})
		})
	})

	Convey("KodingNetworkFS#getFile", tt, func() {
		Convey("It should return error if specified id is not a file", func() {
			k := newknfs(t)
			k.liveNodes[i] = newDir()

			_, err := k.getFile(ctx, i)
			So(err, ShouldEqual, fuse.EIO)
		})

		Convey("It should return file with specified id", func() {
			k := newknfs(t)
			k.liveNodes[i] = newFile()

			file, err := k.getEntry(ctx, i)
			So(err, ShouldBeNil)
			So(file, ShouldHaveSameTypeAs, &File{})
		})
	})

	Convey("KodingNetworkFS#getEntry", tt, func() {
		Convey("It should return error if specified id doesn't exit", func() {
			k := newknfs(t)
			_, err := k.getEntry(ctx, i)
			So(err, ShouldEqual, fuse.ENOENT)
		})

		Convey("It should return entry with specified id", func() {
			k := newknfs(t)
			k.liveNodes[i] = newDir()

			_, err := k.getEntry(ctx, i)
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

		ctx := context.TODO()

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

			node, err := k.getByHandle(ctx, handleId)
			So(err, ShouldBeNil)
			So(node.GetID(), ShouldEqual, d.GetID())
		})

		Convey("It should get dir with handle id", func() {
			handleId := k.setEntryByHandle(d)

			savedDir, err := k.getDirByHandle(ctx, handleId)
			So(err, ShouldBeNil)
			So(savedDir.GetType(), ShouldEqual, fuseutil.DT_Directory)
		})

		Convey("It should get file with handle id", func() {
			handleId := k.setEntryByHandle(f)

			savedFile, err := k.getFileByHandle(ctx, handleId)
			So(err, ShouldBeNil)
			So(savedFile.GetType(), ShouldEqual, fuseutil.DT_File)
		})

		Convey("It should delete file with handle id", func() {
			handleId := k.setEntryByHandle(f)

			k.deleteEntryByHandle(handleId)

			_, err := k.getFileByHandle(ctx, handleId)
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
// argument is ctx, a remote transport is automatically setup.
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
