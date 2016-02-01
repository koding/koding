package klientctlerrors

import (
	"errors"
	"testing"

	"github.com/koding/kite"
	. "github.com/smartystreets/goconvey/convey"
)

func TestIsGetKitesFailure(t *testing.T) {
	Convey("Given a getKites Kite error", t, func() {
		err := &kite.Error{
			Type:    "timeout",
			Message: `No response to "getKodingKites"`,
		}

		Convey("Then return true", func() {
			So(IsGetKitesFailure(err), ShouldBeTrue)
		})
	})

	Convey("Given a kite error with the wrong type", t, func() {
		err := &kite.Error{
			Type:    "foo",
			Message: `No response to "getKodingKites"`,
		}

		Convey("Then return false", func() {
			So(IsGetKitesFailure(err), ShouldBeFalse)
		})
	})

	Convey("Given a kite error with the wrong message", t, func() {
		err := &kite.Error{
			Type:    "timeout",
			Message: "foo",
		}

		Convey("Then return false", func() {
			So(IsGetKitesFailure(err), ShouldBeFalse)
		})
	})

	Convey("Given a non-kite error", t, func() {
		err := errors.New(`timeout: No response to "getKodingKites"`)

		Convey("Then return false", func() {
			So(IsGetKitesFailure(err), ShouldBeFalse)
		})
	})
}

func TestIsSessionNotEstablishedFailure(t *testing.T) {
	Convey("Given a sendError Kite error", t, func() {
		err := &kite.Error{
			Type:    "sendError",
			Message: `can't send, session is not established yet`,
		}

		Convey("Then return true", func() {
			So(IsSessionNotEstablishedFailure(err), ShouldBeTrue)
		})
	})

	Convey("Given a kite error with the wrong type", t, func() {
		err := &kite.Error{
			Type:    "foo",
			Message: `can't send, session is not established yet`,
		}

		Convey("Then return false", func() {
			So(IsSessionNotEstablishedFailure(err), ShouldBeFalse)
		})
	})

	Convey("Given a kite error with the wrong message", t, func() {
		err := &kite.Error{
			Type:    "sendError",
			Message: `foo`,
		}

		Convey("Then return false", func() {
			So(IsSessionNotEstablishedFailure(err), ShouldBeFalse)
		})
	})

	Convey("Given a non-kite error", t, func() {
		err := errors.New(`sendError: can't send, session is not established yet`)

		Convey("Then return false", func() {
			So(IsSessionNotEstablishedFailure(err), ShouldBeFalse)
		})
	})
}
