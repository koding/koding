package fuseklient

import (
	"fmt"
	"io"
	"koding/fuseklient/transport"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var dftCnt = []byte("Hello World!")

func TestContentReadWriterCreate(t *testing.T) {
	Convey("Create", t, func() {
		cr, rt, err := newContentReader()
		So(err, ShouldBeNil)

		Convey("It should return error if file size > 0", func() {
			So(cr.Size, ShouldBeGreaterThan, 0)
			So(cr.Create(), ShouldEqual, ErrCreateOnNotEmpty)
		})

		Convey("It should create file at path with in memory contents", func() {
			cr.Size = 0 // reset test initializer set size
			cr.content = []byte("Hello")

			So(cr.Create(), ShouldBeNil)

			resp, err := rt.ReadFile(cr.Path)
			So(err, ShouldBeNil)

			So(resp.Content, ShouldResemble, []byte("Hello"))
		})
	})
}

func TestContentReadWriterTruncateTo(t *testing.T) {
	Convey("TruncateTo", t, func() {
		Convey("It should add extra padding to content if specified size is greater than size", func() {
		})

		Convey("It should not change content if specified size is same as size", func() {
		})

		Convey("It should truncate to size: 0", func() {
			Convey("It should save truncated content", func() {
			})
		})

		Convey("It should truncate to size: 1", func() {
			Convey("It should save truncated content", func() {
			})
		})
	})
}

func TestContentReadWriterSave(t *testing.T) {
	Convey("Save", t, func() {
		cr, rt, err := newContentReader()
		So(err, ShouldBeNil)

		Convey("It should save contents to remote when dirty", func() {
			So(cr.WriteAt(dftCnt, 0), ShouldBeNil)
			So(cr.Save(false), ShouldBeNil)

			resp, err := rt.ReadFile(cr.Path)
			So(err, ShouldBeNil)

			So(resp.Content, ShouldResemble, dftCnt)
		})

		Convey("It should not save contents to remote when not dirty", func() {
			cr.remote = nil // this causes panic if it calls remote
			So(cr.Save(false), ShouldBeNil)
		})

		Convey("It should force save when specificed", func() {
			cr.remote = nil // this causes panic if it calls remote

			So(func() { cr.Save(false) }, ShouldNotPanic)
			So(func() { cr.Save(true) }, ShouldPanic)
		})
	})
}

func TestContentReadWriterWriteAt(t *testing.T) {
	Convey("WriteAt", t, func() {
		cr, _, err := newContentReader()
		So(err, ShouldBeNil)

		Convey("It should write specified byte slice to memory", func() {
			err := cr.WriteAt(dftCnt, 0)
			So(err, ShouldBeNil)

			So(cr.Size, ShouldEqual, len(dftCnt))

			So(readAt(cr, 0, dftCnt), ShouldBeNil)

			Convey("It should append to pre-existing byte slice", func() {
				err := cr.WriteAt(dftCnt, int64(len(dftCnt)))
				So(err, ShouldBeNil)

				So(readAt(cr, 0, append(dftCnt, dftCnt...)), ShouldBeNil)
			})
		})

		Convey("WriteAt after reset", func() {
			So(cr.WriteAt(dftCnt, 0), ShouldBeNil)

			cr.Reset()

			d := []byte("Holla")
			err := cr.WriteAt(d, 0)
			So(err, ShouldBeNil)

			Convey("It should fetch content from memory before changing content", func() {
				So(cr.Size, ShouldEqual, len(dftCnt))

				So(readAt(cr, 0, []byte("Holla World")), ShouldBeNil)
			})
		})
	})
}

func TestContentReadWriterReset(t *testing.T) {
	Convey("Reset", t, func() {
		cr, _, err := newContentReader()
		So(err, ShouldBeNil)

		cr.Reset()

		Convey("It should return empty byte slice for read", func() {
			cr.remote = nil // this causes panic if it calls remote
			So(func() { cr.ReadAll() }, ShouldPanic)
		})
	})
}

func TestContentReadWriterReadAll(t *testing.T) {
	Convey("ReadAll", t, func() {
		cr, _, err := newContentReader()
		So(err, ShouldBeNil)

		Convey("It should fetch content from remote if not in memory", func() {
			So(cr.ReadAll(), ShouldBeNil)
			So(readAt(cr, 0, dftCnt), ShouldBeNil)

			Convey("It should return from memory if entire file is in memory", func() {
				cr.remote = nil // this causes panic if it calls remote
				So(cr.ReadAll(), ShouldBeNil)
			})
		})

		Convey("It should fetch in batches of BlockSize", func() {
			// this would require len(c.content) times to fetch content since we're
			// fetching 1 byte at a time
			cr.BlockSize = 1

			So(cr.ReadAll(), ShouldBeNil)
			So(readAt(cr, 0, dftCnt), ShouldBeNil)
		})
	})
}

func TestContentReadWriterReadAt(t *testing.T) {
	Convey("ReadAt", t, func() {
		cr, _, err := newContentReader()
		So(err, ShouldBeNil)

		Convey("It should return EOF if offset is same as size", func() {
			_, err := cr.ReadAt(nil, int64(len(dftCnt)))
			So(err, ShouldEqual, io.EOF)
		})

		Convey("It should return EOF if offset is greater than size", func() {
			_, err := cr.ReadAt(nil, int64(len(dftCnt)+1))
			So(err, ShouldEqual, io.EOF)
		})

		Convey("It should fetch content from remote if not in memory", func() {
			So(readAt(cr, 0, dftCnt), ShouldBeNil)
		})

		Convey("It should return from offset to end of file", func() {
			So(readAt(cr, 1, dftCnt[1:]), ShouldBeNil)
		})
	})
}

func newContentReader() (*ContentReadWriter, transport.Transport, error) {
	rt, err := newRemoteTransport()
	if err != nil {
		return nil, nil, err
	}

	if err := rt.WriteFile("1", dftCnt); err != nil {
		return nil, nil, err
	}

	cr := NewContentReadWriter(rt, "1", int64(len(dftCnt)))
	rt, ok := cr.remote.(*transport.RemoteTransport)
	if !ok {
		return nil, nil, fmt.Errorf(
			"unable to cast ContentReadWriter#remote into trnasport.RemoteTransport",
		)
	}

	return cr, rt, nil
}

type readAtInterface interface {
	ReadAt([]byte, int64) (int, error)
}

func readAt(cr readAtInterface, offset int64, expected []byte) error {
	r := make([]byte, len(expected))
	n, err := cr.ReadAt(r, offset)
	if err != nil {
		return err
	}

	if n != len(expected) {
		return fmt.Errorf(
			"expected %d written to result slice, got %d instead", len(expected), n,
		)
	}

	if len(r) != len(expected) {
		return fmt.Errorf(
			"expected result: %d to have same size of expected: %d", len(r), len(expected),
		)
	}

	if string(expected) != string(r) {
		return fmt.Errorf(
			"expected %s to equal %s", string(expected), string(r),
		)
	}

	return nil
}
