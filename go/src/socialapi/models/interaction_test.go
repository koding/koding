package models

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestInteractiongetAccountId(t *testing.T) {
	Convey("while getting account id", t, func() {
		Convey("it should have error if interaction id is not set", func() {
			i := NewInteraction()

			in, err := i.getAccountId()
			So(err, ShouldNotBeNil)
			So(err.Error(), ShouldContainSubstring, "couldnt find accountId from content")
			So(in, ShouldEqual, 0)
		})
	})
}
