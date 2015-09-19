package fs

import (
	"encoding/base64"
	"io"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestFile(tt *testing.T) {
	Convey("NewFile", tt, func() {
		Convey("It should initialize new File", func() {
			i := &Entry{Transport: &fakeTransport{}, RemotePath: "/remote/file"}
			f := NewFile(i)

			Convey("It should initialize content", func() {
				So(len(f.Content), ShouldEqual, 0)
			})
		})
	})

	Convey("File#ReadAt", tt, func() {
		Convey("It should return contents at specified offset: 0", func() {
			f := newFile()

			content, err := f.ReadAt(0)
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "Hello World!")
		})

		Convey("It should return contents at specified offset: 1", func() {
			f := newFile()

			content, err := f.ReadAt(1)
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "ello World!")
		})

		Convey("It should fetch content from remote if content is empty", func() {
			f := newFileWithTransport()

			content, err := f.ReadAt(0)
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "Hello World!")
		})

		Convey("It should not fetch content from remote if content exists", func() {
			f := newFileWithTransport()

			content, err := f.ReadAt(0)
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "Hello World!")

			f.Transport = &fakeTransport{}

			content, err = f.ReadAt(0)
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "Hello World!")
		})

		Convey("It should return error if offset is greater than length of contents", func() {
			f := newFile()

			_, err := f.ReadAt(int64(len(f.Content) + 1))
			So(err, ShouldEqual, io.EOF)
		})
	})

	Convey("File#WriteAt", tt, func() {
		Convey("It should write specified content at beginning of file", func() {
			f := newFile()
			f.Content = []byte("Hello World!")

			c := []byte("Hi")
			f.WriteAt(c, 0)
			So(string(f.Content), ShouldEqual, "Hi")
		})

		Convey("It should write specified content at end of file", func() {
			f := newFile()
			f.Content = []byte("Hello World!")

			c := []byte("!")
			o := int64(len(f.Content)) // 0 indexed
			f.WriteAt(c, o)

			So(string(f.Content), ShouldEqual, "Hello World!!")
		})

		Convey("It should update fields", func() {
			f := newFile()
			f.Content = []byte("Hello World!")

			c := []byte("Hi")
			f.WriteAt(c, 0)

			Convey("It should set dirty state to true", func() {
				So(f.IsDirty, ShouldBeTrue)
			})

			Convey("It should update size", func() {
				So(f.Attrs.Size, ShouldEqual, len(c))
			})
		})
	})

	Convey("File#TruncateTo", tt, func() {
		Convey("It should add extra padding to content if specified size is greater than size of file", func() {
			f := newFileWithTransport()
			f.Content = []byte("Hello World!")

			oldSize := len(f.Content)

			So(f.TruncateTo(uint64(len(f.Content)+1)), ShouldBeNil)
			So(len(f.Content), ShouldEqual, oldSize+1)
		})

		Convey("It should not change content if specified size is same as size of file", func() {
			f := newFileWithTransport()
			f.Content = []byte("Hello World!")

			size := len(f.Content)

			So(f.TruncateTo(uint64(size)), ShouldBeNil)
			So(len(f.Content), ShouldEqual, size)
		})

		Convey("It should remove content at end if specified size is smaller than size of file", func() {
			Convey("It should truncate file to size: 0", func() {
				f := newFileWithTransport()
				f.Content = []byte("Hello World!")

				So(f.TruncateTo(0), ShouldBeNil)

				Convey("It should save truncated contents", func() {
					So(len(f.Content), ShouldEqual, 0)
				})
			})

			Convey("It should truncate file to size: 1", func() {
				f := newFileWithTransport()
				f.Content = []byte("Hello World!")

				So(f.TruncateTo(1), ShouldBeNil)

				Convey("It should save truncated contents", func() {
					So(len(f.Content), ShouldEqual, 1)
				})
			})
		})
	})

	Convey("File#writeContentToRemote", tt, func() {
		Convey("It should specificed content to remote", func() {
			c := []byte("Hello World!")

			f := newFileWithTransport()
			So(f.writeContentToRemote(c), ShouldBeNil)
		})

		Convey("It should reset dirty state", func() {
			c := []byte("Hello World!")

			f := newFileWithTransport()
			f.IsDirty = true

			So(f.writeContentToRemote(c), ShouldBeNil)

			So(f.IsDirty, ShouldBeFalse)
		})
	})

	Convey("File#getContentFromRemote", tt, func() {
		Convey("It should return contents after fetching them from remote", func() {
			f := newFileWithTransport()

			content, err := f.getContentFromRemote()
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "Hello World!")
		})
	})
}

func newFileWithTransport() *File {
	c := base64.StdEncoding.EncodeToString([]byte("Hello World!"))
	t := &fakeTransport{
		TripResponses: map[string]interface{}{
			"fs.readFile":  map[string]interface{}{"content": c},
			"fs.writeFile": 1,
		},
	}
	i := &Entry{Transport: t}

	return NewFile(i)
}

func newFile() *File {
	i := &Entry{Transport: &fakeTransport{}, RemotePath: "/remote/file"}
	f := NewFile(i)
	f.Content = []byte("Hello World!")

	return f
}
