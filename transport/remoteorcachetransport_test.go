package transport

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRemoteOrCacheTransport(t *testing.T) {
	var _ Transport = (*RemoteOrCacheTransport)(nil)
}

func TestNewRemoteOrCacheTransport(t *testing.T) {
	Convey("It should set ignore dirs for RemoteTransport", t, func() {
		rt := &RemoteTransport{
			IgnoreDirs: defaultDirIgnoreList,
		}
		dt := &DiskTransport{}

		NewRemoteOrCacheTransport(rt, dt)
		So(len(rt.IgnoreDirs), ShouldEqual, 0)
	})
}
