package fuseklient

import (
	"os"
	"testing"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/koding/fuseklient/transport"
	. "github.com/smartystreets/goconvey/convey"
)

func TestEntry(t *testing.T) {
	Convey("NewRootEntry", t, func() {
		Convey("It should initialize Entry", func() {
			entry := newEntry()

			Convey("It should set id to fuse root id", func() {
				So(entry.ID, ShouldEqual, fuseops.RootInodeID)
			})
		})
	})

	Convey("Entry#Open", t, func() {
		Convey("It should open a entry", func() {
			entry := newEntry()
			entry.Open()

			Convey("It should increment hard links to entry", func() {
				So(entry.Attrs.Nlink, ShouldEqual, 1)
			})
		})
	})

	Convey("Entry#Release", t, func() {
		Convey("It should release an opened entry", func() {
			entry := newEntry()
			entry.Open()
			entry.Open()
			entry.Release()

			Convey("It should set hard links to 0", func() {
				So(entry.Attrs.Nlink, ShouldEqual, 0)
			})
		})
	})

	Convey("Entry#Forget", t, func() {
		Convey("It should forget a entry", func() {
			entry := newEntry()
			entry.Forget()

			Convey("It should set forgetten to true", func() {
				So(entry.Forgotten, ShouldBeTrue)
			})
		})
	})

	Convey("Entry#IsForgotten", t, func() {
		Convey("It should true if entry is live", func() {
			entry := newEntry()
			So(entry.IsForgotten(), ShouldBeFalse)
		})

		Convey("It should true if entry has been forgotten", func() {
			entry := newEntry()

			entry.Forget()
			So(entry.IsForgotten(), ShouldBeTrue)
		})
	})

	Convey("Entry#Rename", t, func() {
		Convey("It should rename a entry", func() {
			entry := newEntry()
			entry.Rename("folder1")

			Convey("It should set name to new name", func() {
				So(entry.Name, ShouldEqual, "folder1")
			})
		})
	})

	Convey("Entry#GetAttrs", t, func() {
		Convey("It should set attrs for entry", func() {
			entry := newEntry()
			entry.Attrs = fuseops.InodeAttributes{Uid: 1}
			Convey("It should return attrs", func() {
				newAttrs := entry.GetAttrs()
				So(newAttrs.Uid, ShouldEqual, 1)
			})
		})
	})

	Convey("Entry#SetAttrs", t, func() {
		Convey("It should set attrs for entry", func() {
			attrs := fuseops.InodeAttributes{Uid: 1}
			entry := newEntry()
			entry.SetAttrs(attrs)

			So(entry.Attrs.Uid, ShouldEqual, attrs.Uid)
		})
	})

	Convey("Entry#getAttrsFromRemote", t, func() {
		Convey("It should return error if entry doesn't exist", func() {
			entry := newEntry()
			entry.Transport = &fakeTransport{
				TripResponses: map[string]interface{}{
					"fs.getInfo": transport.FsGetInfoRes{},
				},
			}

			_, err := entry.getAttrsFromRemote()
			So(err, ShouldEqual, fuse.ENOENT)
		})

		Convey("It should fetch attributes from remote", func() {
			entry := newEntryWithFolderResp()
			attrs, err := entry.getAttrsFromRemote()
			So(err, ShouldBeNil)

			So(attrs.Mode, ShouldEqual, os.FileMode(0755))
		})
	})

	Convey("Entry#updateAttrsFromRemote", t, func() {
		Convey("It should update attrs after fetching them from remote", func() {
			entry := newEntryWithFolderResp()
			So(entry.Attrs.Size, ShouldEqual, 0)

			So(entry.updateAttrsFromRemote(), ShouldBeNil)
			So(entry.Attrs.Size, ShouldEqual, 1)
		})
	})
}

func newEntryWithFolderResp() *Entry {
	entry := newEntry()
	entry.Transport = &fakeTransport{
		TripResponses: map[string]interface{}{
			"fs.getInfo": transport.FsGetInfoRes{
				Exists:   true,
				FullPath: "/remote/folder",
				IsDir:    true,
				Mode:     os.FileMode(0755),
				Name:     "folder",
				Size:     1,
			},
		},
	}

	return entry
}

func newEntry() *Entry {
	t := &fakeTransport{}
	entry := NewRootEntry(t, "/remote", "/local")
	entry.Attrs = fuseops.InodeAttributes{}

	return entry
}
