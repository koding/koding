package metrics

import (
	. "github.com/smartystreets/goconvey/convey"
	"testing"
)

func TestInitTrackers(t *testing.T) {
	Convey("init trackers", t, func() {
		trackers := InitTrackers(
			NewMixpanelTracker("113c2731b47a5151f4be44ddd5af0e7a"),
		)

		So(len(trackers.List), ShouldEqual, 1)
	})

	Convey("track event", t, func() {
		trackers := InitTrackers(
			NewMixpanelTracker("113c2731b47a5151f4be44ddd5af0e7a"),
		)

		err := trackers.Track("from metrics_test")

		So(err, ShouldEqual, nil)
	})

	Convey("track event with properties", t, func() {
		trackers := InitTrackers(
			NewMixpanelTracker("113c2731b47a5151f4be44ddd5af0e7a"),
		)

		err := trackers.TrackWithProp("from metrics_test", Prop{
			"username": "whatever",
		})

		So(err, ShouldEqual, nil)
	})
}
