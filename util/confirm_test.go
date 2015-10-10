package util

import (
	"bytes"
	"fmt"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestYesNoConfirmWithDefault(t *testing.T) {
	Convey("Should return true with yes or y", t, func() {
		var in bytes.Buffer
		fmt.Fprintln(&in, "yes")
		res, err := YesNoConfirmWithDefault(&in, false)
		So(err, ShouldBeNil)
		So(res, ShouldBeTrue)
		fmt.Fprintln(&in, "y")
		res, err = YesNoConfirmWithDefault(&in, false)
		So(err, ShouldBeNil)
		So(res, ShouldBeTrue)
	})

	Convey("Should return false with no or n", t, func() {
		var in bytes.Buffer
		fmt.Fprintln(&in, "no")
		res, err := YesNoConfirmWithDefault(&in, true)
		So(err, ShouldBeNil)
		So(res, ShouldBeFalse)
		fmt.Fprintln(&in, "n")
		res, err = YesNoConfirmWithDefault(&in, true)
		So(err, ShouldBeNil)
		So(res, ShouldBeFalse)
	})

	Convey("Should return the default value for an empty line", t, func() {
		var in bytes.Buffer
		fmt.Fprintln(&in, "\n")
		res, err := YesNoConfirmWithDefault(&in, true)
		So(err, ShouldBeNil)
		So(res, ShouldBeTrue)
		fmt.Fprintln(&in, "\n")
		res, err = YesNoConfirmWithDefault(&in, false)
		So(err, ShouldBeNil)
		So(res, ShouldBeFalse)
	})

	Convey("Should return an error unexpected input", t, func() {
		var in bytes.Buffer
		fmt.Fprintln(&in, "hello frank")
		_, err := YesNoConfirmWithDefault(&in, true)
		So(err, ShouldNotBeNil)
	})
}
