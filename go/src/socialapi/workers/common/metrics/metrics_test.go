package metrics

import (
	. "github.com/smartystreets/goconvey/convey"
	"testing"
)

type FakeTracker struct{}

func (t *FakeTracker) Track(string, Prop) error {
	return nil
}

func initTrackers() *Trackers {
	trackers := InitTrackers(&FakeTracker{})
	return trackers
}

func TestInitTrackers(t *testing.T) {
	Convey("init trackers", t, func() {
		trackers := initTrackers()
		So(len(trackers.List), ShouldEqual, 1)
	})

	Convey("track event", t, func() {
		trackers := initTrackers()
		err := trackers.Track("from metrics_test")

		So(err, ShouldEqual, nil)
	})

	Convey("track event with properties", t, func() {
		trackers := initTrackers()
		err := trackers.TrackWithProp("from metrics_test", Prop{
			"username": "whatever",
		})

		So(err, ShouldEqual, nil)
	})
}
