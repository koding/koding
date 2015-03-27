package eventexporter

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestSegmentIOExporter(t *testing.T) {
	Convey("When using SegmentIOExporter", t, func() {
		Convey("Then it should return err if no username", func() {
			user := &User{}
			event := &Event{Name: "test", User: user}
			_, err := buildTrack(event)

			So(err, ShouldEqual, ErrSegmentIOUsernameEmpty)
		})

		Convey("Then it should return err if no email", func() {
			user := &User{Username: "indianajones"}
			event := &Event{Name: "test", User: user}
			_, err := buildTrack(event)

			So(err, ShouldEqual, ErrSegmentIOEmailEmpty)
		})

		Convey("Then it should return err if no event name", func() {
			user := &User{Username: "indianajones", Email: "senthil@koding.com"}
			event := &Event{Name: "", User: user}
			_, err := buildTrack(event)

			So(err, ShouldEqual, ErrSegmentIOEventEmpty)
		})

		Convey("Then it should send", func() {
			props := map[string]interface{}{"key": "a"}
			user := &User{Username: "indianajones", Email: "senthil@koding.com"}
			event := &Event{Name: "test", Properties: props, User: user}

			_, err := buildTrack(event)
			So(err, ShouldBeNil)
		})
	})
}
