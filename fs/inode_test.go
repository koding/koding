package fs

import (
	"os"
	"testing"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseops"
	"github.com/koding/fuseklient/transport"
	. "github.com/smartystreets/goconvey/convey"
)

func TestNode(t *testing.T) {
	Convey("NewRootNode", t, func() {
		Convey("It should initialize Node", func() {
			node := newInode()

			Convey("It should set id to fuse root id", func() {
				So(node.ID, ShouldEqual, fuseops.RootInodeID)
			})
		})
	})

	Convey("Inode#Open", t, func() {
		Convey("It should open a Node", func() {
			node := newInode()
			node.Open()

			Convey("It should increment hard links to Node", func() {
				So(node.Attrs.Nlink, ShouldEqual, 1)
			})
		})
	})

	Convey("Inode#Release", t, func() {
		Convey("It should release an opened Node", func() {
			node := newInode()
			node.Open()
			node.Open()
			node.Release()

			Convey("It should set hard links to 0", func() {
				So(node.Attrs.Nlink, ShouldEqual, 0)
			})
		})
	})

	Convey("Inode#Forget", t, func() {
		Convey("It should forget a node", func() {
			node := newInode()
			node.Forget()

			Convey("It should set forgetten to true", func() {
				So(node.Forgotten, ShouldBeTrue)
			})
		})
	})

	Convey("Inode#IsForgotten", t, func() {
		Convey("It should true if node is live", func() {
			node := newInode()
			So(node.IsForgotten(), ShouldBeFalse)
		})

		Convey("It should true if node has been forgotten", func() {
			node := newInode()

			node.Forget()
			So(node.IsForgotten(), ShouldBeTrue)
		})
	})

	Convey("Inode#Rename", t, func() {
		Convey("It should rename a node", func() {
			node := newInode()
			node.Rename("folder1")

			Convey("It should set name to new name", func() {
				So(node.Name, ShouldEqual, "folder1")
			})
		})
	})

	Convey("Inode#GetAttrs", t, func() {
		Convey("It should set attrs for Node", func() {
			node := newInode()
			node.Attrs = fuseops.InodeAttributes{Uid: 1}
			Convey("It should return attrs", func() {
				newAttrs := node.GetAttrs()
				So(newAttrs.Uid, ShouldEqual, 1)
			})
		})
	})

	Convey("Inode#SetAttrs", t, func() {
		Convey("It should set attrs for Node", func() {
			attrs := fuseops.InodeAttributes{Uid: 1}
			node := newInode()
			node.SetAttrs(attrs)

			So(node.Attrs.Uid, ShouldEqual, attrs.Uid)
		})
	})

	Convey("Inode#getAttrsFromRemote", t, func() {
		Convey("It should return error if entry doesn't exist", func() {
			node := newInode()
			node.Transport = &fakeTransport{
				TripResponses: map[string]interface{}{
					"fs.getInfo": transport.FsGetInfoRes{},
				},
			}

			_, err := node.getAttrsFromRemote()
			So(err, ShouldEqual, fuse.ENOENT)
		})

		Convey("It should fetch attributes from remote", func() {
			node := newInodeWithFolderResp()
			attrs, err := node.getAttrsFromRemote()
			So(err, ShouldBeNil)

			So(attrs.Mode, ShouldEqual, os.FileMode(0755))
		})
	})

	Convey("Inode#updateAttrsFromRemote", t, func() {
		Convey("It should update attrs after fetching them from remote", func() {
			node := newInodeWithFolderResp()
			So(node.Attrs.Size, ShouldEqual, 0)

			So(node.updateAttrsFromRemote(), ShouldBeNil)
			So(node.Attrs.Size, ShouldEqual, 1)
		})
	})
}

func newInodeWithFolderResp() *Inode {
	inode := newInode()
	inode.Transport = &fakeTransport{
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

	return inode
}

func newInode() *Inode {
	t := &fakeTransport{}
	inode := NewRootInode(t, "/remote", "/local")
	inode.Attrs = fuseops.InodeAttributes{}

	return inode
}
