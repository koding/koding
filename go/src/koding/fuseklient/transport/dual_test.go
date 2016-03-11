package transport

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestDualTransport(t *testing.T) {
	var _ Transport = (*DualTransport)(nil)
}

func TestNewDualTransport(t *testing.T) {
	Convey("It should set ignore dirs for RemoteTransport", t, func() {
		rt := &RemoteTransport{
			IgnoreDirs: defaultDirIgnoreList,
		}
		dt := &DiskTransport{}

		NewDualTransport(rt, dt)
		So(len(rt.IgnoreDirs), ShouldEqual, 0)
	})
}
