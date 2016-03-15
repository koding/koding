package fuseklient

import (
	"io"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestFileNewFile(tt *testing.T) {
	Convey("NewFile", tt, func() {
		Convey("It should initialize new File", func() {
			f, err := newFile()
			So(err, ShouldBeNil)

			Convey("It should initialize content", func() {
				So(f.content, ShouldNotBeNil)
			})
		})
	})
}

func TestFileReadAt(tt *testing.T) {
	Convey("ReadAt", tt, func() {
		f, err := newFile()
		So(err, ShouldBeNil)

		Convey("It should return content at specified offset: 0", func() {
			So(readAt(f, 0, dftCnt), ShouldBeNil)
		})

		Convey("It should return content at specified offset: 1", func() {
			So(readAt(f, 1, dftCnt[1:]), ShouldBeNil)
		})

		Convey("It should not fetch content from remote if content is same size as Attrs#Size", func() {
			So(readAt(f, 0, dftCnt), ShouldBeNil)

			f.Transport = nil // this causes panic if next method call hits remote

			So(readAt(f, 0, dftCnt), ShouldBeNil)
		})

		Convey("It should return error if offset is equal to length of content", func() {
			_, err = f.ReadAt(nil, int64(f.Attrs.Size))
			So(err, ShouldEqual, io.EOF)
		})

		Convey("It should return error if offset is greater than length of content", func() {
			_, err := f.ReadAt(nil, int64(f.Attrs.Size)+1)
			So(err, ShouldEqual, io.EOF)
		})
	})
}

func TestFileWriteAt(tt *testing.T) {
	Convey("WriteAt", tt, func() {
		f, err := newFile()
		So(err, ShouldBeNil)

		Convey("It should write specified content at beginning of file", func() {
			f.WriteAt([]byte("Holla"), 0)
			So(readAt(f, 0, []byte("Holla World!")), ShouldBeNil)
		})

		Convey("It should write specified content at end of file", func() {
			f.WriteAt([]byte("!"), int64(f.Attrs.Size)) // 0 indexed
			So(readAt(f, 0, []byte("Hello World!!")), ShouldBeNil)
		})

		Convey("It should update file size on write", func() {
			f.WriteAt([]byte("!"), int64(f.Attrs.Size))
			So(f.Attrs.Size, ShouldEqual, len(dftCnt)+1)
		})
	})
}

func TestFileTruncateTo(tt *testing.T) {
	Convey("TruncateTo", tt, func() {
		f, err := newFile()
		So(err, ShouldBeNil)

		Convey("It should add extra padding to content if specified size is greater than size of file", func() {
			oldSize := f.Attrs.Size

			So(f.TruncateTo(uint64(oldSize+1)), ShouldBeNil)
			So(f.Attrs.Size, ShouldEqual, oldSize+1)
		})

		Convey("It should not change content if specified size is same as size of file", func() {
			size := f.Attrs.Size

			So(f.TruncateTo(uint64(size)), ShouldBeNil)
			So(f.Attrs.Size, ShouldEqual, size)
		})

		Convey("It should remove content at end if specified size is smaller than size of file", func() {
			Convey("It should truncate file to size: 0", func() {
				So(f.TruncateTo(0), ShouldBeNil)

				Convey("It should save truncated content", func() {
					So(f.Attrs.Size, ShouldEqual, 0)
				})
			})

			Convey("It should truncate file to size: 1", func() {
				So(f.TruncateTo(1), ShouldBeNil)

				Convey("It should save truncated content", func() {
					So(f.Attrs.Size, ShouldEqual, 1)
				})
			})
		})
	})
}

func TestFileExpire(tt *testing.T) {
	Convey("Expire", tt, func() {
		Convey("It should increase inode id of itself", func() {
			f, err := newFile()
			So(err, ShouldBeNil)

			id := f.ID

			So(f.Expire(), ShouldBeNil)

			So(f.ID, ShouldNotEqual, id)
		})
	})
}

func newFile() (*File, error) {
	rt, err := newRemoteTransport()
	if err != nil {
		return nil, err
	}

	if err := rt.WriteFile("1", dftCnt); err != nil {
		return nil, err
	}

	d := newDir()
	d.Path = ""

	i := NewEntry(d, "1")
	i.Attrs.Size = uint64(len(dftCnt))

	f := NewFile(i)

	return f, nil
}
