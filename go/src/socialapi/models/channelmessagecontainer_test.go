package models

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelMessageContainerNewChannelMessageContainer(t *testing.T) {

	c := NewChannelMessageContainer()

	Convey("given a NewChannelMessageContainer", t, func() {

		Convey("it should not be nil", func() {
			So(c, ShouldNotBeEmpty)
		})
	})
}

func TestChannelMessageContainerNewInteractionContainer(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	c := NewInteractionContainer()

	Convey("given a NewInteractionContainer", t, func() {

		Convey("it should not be nil", func() {
			So(c, ShouldNotBeEmpty)
		})

		Convey("it should have actors preview as set", func() {
			So(c.ActorsPreview, ShouldBeEmpty)
		})

		Convey("it should have isInteracted as set", func() {
			So(c.IsInteracted, ShouldEqual, false)
		})

		Convey("it should have actorscount as set", func() {
			So(c.ActorsCount, ShouldEqual, 0)
		})
	})
}
