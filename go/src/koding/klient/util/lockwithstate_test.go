package util

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMutexWithStateLock(t *testing.T) {
	Convey("Given a MutextWithState", t, func() {
		m := NewMutexWithState()
		So(m.IsLocked(), ShouldBeFalse)

		Convey("It should set IsLocked when locked", func() {
			m.Lock()
			So(m.IsLocked(), ShouldBeTrue)
		})
	})
}

func TestMutexWithStateUnlock(t *testing.T) {
	Convey("Given a MutextWithState", t, func() {
		m := NewMutexWithState()
		So(m.IsLocked(), ShouldBeFalse)
		m.Lock()
		So(m.IsLocked(), ShouldBeTrue)

		Convey("It should set IsLocked when unlocked", func() {
			m.Unlock()
			So(m.IsLocked(), ShouldBeFalse)
		})
	})
}
