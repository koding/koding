package metrics

import (
	. "github.com/smartystreets/goconvey/convey"
	"testing"
)

func initTrackers() *Trackers {
	trackers := InitTrackers(
		NewMixpanelTracker("113c2731b47a5151f4be44ddd5af0e7a"),
	)

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
