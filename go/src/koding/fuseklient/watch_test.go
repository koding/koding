package fuseklient

import (
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestFindWatcher(t *testing.T) {
	Convey("It should implement Watcher interface", t, func() {
		var _ Watcher = (*FindWatcher)(nil)
	})

	ft := &fakeTransport{
		TripResponses: map[string]interface{}{"indiana": struct{ Name string }{"jones"}},
	}

	fw := NewFindWatcher(ft, "/remote")

	Convey("FindWatcher#AddTimedIgnore", t, func() {
		Convey("It should add paths to ignore for till timeout", func() {
			fw.AddTimedIgnore("/remote/a")

			dur, ok := fw.ignoredPaths["/remote/a"]
			So(ok, ShouldBeTrue)
			So(dur.After(time.Now()), ShouldBeTrue)
		})
	})

	Convey("FindWatcher#RemoveTimedIgnore", t, func() {
		Convey("It should removes path with remote prefix", func() {
			fw.AddTimedIgnore("/remote/a")
			fw.removeTimedIgnore("/remote/a")

			_, ok := fw.ignoredPaths["/remote/a"]
			So(ok, ShouldBeFalse)
		})
	})

	Convey("FindWatcher#isPathIgnored", t, func() {
		Convey("It should return false if path is not in list", func() {
			isIgnored := fw.isPathIgnored("random")
			So(isIgnored, ShouldBeFalse)
		})

		Convey("It should return false if path is in list and has expired", func() {
			fw.AddTimedIgnore("/remote/a")

			isIgnored := fw.isPathIgnored("expired")
			So(isIgnored, ShouldBeFalse)
		})

		Convey("It should remove path from list if it has expired", func() {
			fw.AddTimedIgnore("/remote/a")

			_, ok := fw.ignoredPaths["expired"]
			So(ok, ShouldBeFalse)
		})

		Reset(func() { fw.ignoredPaths = map[string]time.Time{} })
	})

	Convey("FindWatcher#getChangedFiles", t, func() {
	})
}
