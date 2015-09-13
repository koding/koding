package fs

import (
	"os"
	"testing"

	"github.com/jacobsa/fuse"
	"github.com/jacobsa/fuse/fuseutil"
	"github.com/koding/fuseklient/transport"
	. "github.com/smartystreets/goconvey/convey"
)

func newNode() *Node {
	t := &fakeTransport{
		TripResponses: map[string]interface{}{
			"fs.readDirectory": transport.FsReadDirectoryRes{
				Files: []transport.FsGetInfoRes{transport.FsGetInfoRes{
					Exists:   true,
					FullPath: "/remote/folder",
					IsDir:    true,
					Mode:     os.FileMode(0700),
					Name:     "folder",
				}, transport.FsGetInfoRes{
					Exists:   true,
					FullPath: "/remote/file",
					IsDir:    false,
					Mode:     os.FileMode(0755),
					Name:     "file",
				}},
			},
		},
	}

	i := NewNodeIDGen()

	node := NewNode(t, i)
	node.EntryType = fuseutil.DT_Directory
	node.RemotePath = "/remote"
	node.LocalPath = "/local"
	node.Attrs.Uid = 01
	node.Attrs.Gid = 02

	return node
}

func TestNode(tt *testing.T) {
	node := newNode()

	Convey("It should initialize child node", tt, func() {
		nextId := node.NodeIDGen.Next()
		childNode := node.InitializeChildNode("child", nextId)

		Convey("It should set child node properties", func() {
			So(childNode.ID, ShouldEqual, nextId)
			So(childNode.Name, ShouldEqual, "child")
			So(childNode.RemotePath, ShouldEqual, "/remote/child")
			So(childNode.LocalPath, ShouldEqual, "/local/child")
			So(childNode.EntryType, ShouldEqual, fuseutil.DT_Directory)
			So(childNode.Attrs.Nlink, ShouldEqual, 1)
			So(childNode.Attrs.Uid, ShouldEqual, 1)
			So(childNode.Attrs.Gid, ShouldEqual, 2)
		})

		Convey("It should save child node in parent node children list", func() {
			So(node.EntriesList["child"], ShouldEqual, childNode)
		})
	})

	Convey("FindChild", tt, func() {
		Convey("It should find and return child node", func() {
			node := newNode()

			c, err := node.FindChild("folder")
			So(err, ShouldBeNil)
			So(c.Name, ShouldEqual, "folder")
		})

		Convey("It should return from cache unless empty", func() {
			node := newNode()
			c, err := node.FindChild("folder")
			So(err, ShouldBeNil)
			So(c.Name, ShouldEqual, "folder")

			// reset Transport so if new remote call is made it will return err
			node.Transport = &fakeTransport{}

			c, err = node.FindChild("folder")
			So(err, ShouldBeNil)
			So(c.Name, ShouldEqual, "folder")
		})
	})

	Convey("ReadDir", tt, func() {
		Convey("It should return error if Node is a file", func() {
			n := newNode()
			n.EntryType = fuseutil.DT_File

			_, err := n.ReadDir()
			So(err, ShouldEqual, fuse.EIO)
		})

		Convey("It should fetch directory entries from user VM", func() {
			node := newNode()

			entries, err := node.getEntriesFromRemote()
			So(err, ShouldBeNil)
			So(len(entries), ShouldEqual, 2)

			folder, file := entries[0], entries[1]

			So(folder.Offset, ShouldEqual, 1)
			So(folder.Inode, ShouldEqual, 2)
			So(folder.Name, ShouldEqual, "folder")
			So(folder.Type, ShouldEqual, fuseutil.DT_Directory)

			So(file.Offset, ShouldEqual, 2)
			So(file.Inode, ShouldEqual, 3)
			So(file.Name, ShouldEqual, "file")
			So(file.Type, ShouldEqual, fuseutil.DT_File)
		})

		Convey("It should save entries to entries list cache", func() {
			node := newNode()
			_, err := node.getEntriesFromRemote()
			So(err, ShouldBeNil)

			So(len(node.EntriesList), ShouldEqual, 2)
		})

		Convey("It should return entries from cache if already fetched", func() {
			node := newNode()

			entries, err := node.ReadDir()
			So(err, ShouldBeNil)
			So(len(entries), ShouldEqual, 2)

			// reset Transport so if new remote call is made it will return err
			node.Transport = &fakeTransport{}

			entries, err = node.ReadDir()
			So(err, ShouldBeNil)
			So(len(entries), ShouldEqual, 2)
		})
	})
}
