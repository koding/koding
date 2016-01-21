package fuseklient

import (
	"encoding/base64"
	"io"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestFile(tt *testing.T) {
	Convey("NewFile", tt, func() {
		Convey("It should initialize new File", func() {
			i := &Entry{Transport: &fakeTransport{}}
			f := NewFile(i)

			Convey("It should initialize content", func() {
				So(len(f.Content), ShouldEqual, 0)
			})
		})
	})

	Convey("File#ReadAt", tt, func() {
		Convey("It should return content at specified offset: 0", func() {
			f := newFile()

			content, err := f.ReadAt(0)
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "Hello World!")
		})

		Convey("It should return content at specified offset: 1", func() {
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

			// reset to empty transport, so if remote call is made, it panics
			f.Transport = &fakeTransport{}

			content, err = f.ReadAt(0)
			So(err, ShouldBeNil)
			So(string(content), ShouldEqual, "Hello World!")
		})

		Convey("It should return error if offset is greater than length of content", func() {
			f := newFile()

			_, err := f.ReadAt(int64(len(f.Content) + 1))
			So(err, ShouldEqual, io.EOF)
		})
	})

	Convey("File#Create", tt, func() {
		Convey("It should create new file in remote", func() {
			f := newFile()
			f.Content = []byte("Hello World!")

			// since transport is empty, if it panics it means it hit remote
			// and there was no response specified
			//So(func() { f.Create() }, ShouldPanicWith, "Expected 'fs.writeFile' to be in list of mocked responses.")

			f = newFileWithTransport()
			f.Content = []byte("Hello World!")

			err := f.Create()
			So(err, ShouldBeNil)
		})

		Convey("It should create file in remote even if content is empty", func() {
			f := newFile()
			f.Content = []byte{}

			// since transport is empty, if it panics it means it hit remote
			// and there was no response specified
			//So(func() { f.Create() }, ShouldPanicWith, "Expected 'fs.writeFile' to be in list of mocked responses.")

			f = newFileWithTransport()
			f.Content = []byte{}

			err := f.Create()
			So(err, ShouldBeNil)
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

				Convey("It should save truncated content", func() {
					So(len(f.Content), ShouldEqual, 0)
				})
			})

			Convey("It should truncate file to size: 1", func() {
				f := newFileWithTransport()
				f.Content = []byte("Hello World!")

				So(f.TruncateTo(1), ShouldBeNil)

				Convey("It should save truncated content", func() {
					So(len(f.Content), ShouldEqual, 1)
				})
			})
		})
	})

	Convey("File#writeContentToRemoteIfDirty", tt, func() {
		Convey("It should not write specified content if not dirty", func() {
			f := newFileWithTransport()

			// reset to empty transport, so if remote call is made, it panics
			f.Transport = &fakeTransport{}
			f.IsDirty = false

			So(f.syncToRemote(), ShouldBeNil)
		})

		Convey("It should write specified content to remove if dirty", func() {
			f := newFileWithTransport()
			f.Content = []byte("Hello World!")
			f.IsDirty = true

			So(f.syncToRemote(), ShouldBeNil)

			Convey("It should set File#IsDirty to false after writing to remote", func() {
				So(f.IsDirty, ShouldBeFalse)
			})
		})
	})

	Convey("File#writeContentToRemote", tt, func() {
		Convey("It should write specificed content to remote", func() {
			c := []byte("Hello World!")

			f := newFileWithTransport()
			So(f.writeContentToRemote(c), ShouldBeNil)

			Convey("It should set File#IsDirty to false after writing to remote", func() {
				So(f.IsDirty, ShouldBeFalse)
			})
		})
	})

	Convey("File#updateContentFromRemote", tt, func() {
		Convey("It should update content after fetching them from remote", func() {
			c := base64.StdEncoding.EncodeToString([]byte("Modified Content"))

			f := newFileWithTransport()
			f.Content = []byte("Hello World!")
			f.Transport = &fakeTransport{
				TripResponses: map[string]interface{}{
					"fs.readFile": map[string]interface{}{"content": c},
				},
			}

			err := f.updateContentFromRemote()
			So(err, ShouldBeNil)
			So(string(f.Content), ShouldEqual, "Modified Content")
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
	i := &Entry{Transport: &fakeTransport{}}
	f := NewFile(i)
	f.Content = []byte("Hello World!")

	return f
}
