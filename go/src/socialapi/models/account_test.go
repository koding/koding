package models

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestAccountNewAccount(t *testing.T) {
	Convey("while testing new account", t, func() {
		Convey("Function call should return account", func() {
			So(NewAccount(), ShouldNotBeNil)
		})
	})
}

func TestAccountGetId(t *testing.T) {
	Convey("while testing get id", t, func() {
		Convey("Initialized struct ", func() {
			Convey("should return given id", func() {
				a := Account{Id: 42}
				So(a.GetId(), ShouldEqual, 42)
			})
			Convey("Uninitialized struct ", func() {
				Convey("should return 0", func() {
					So(NewAccount().GetId(), ShouldEqual, 0)
				})
				So(NewAccount(), ShouldNotBeNil)
			})
		})
	})
}
