package services

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestServiceFactory(t *testing.T) {
	Convey("while testing service factory", t, func() {
		Convey("it should return error when service does not implemented", func() {
			sf := NewServiceFactory()
			_, err := sf.Create("heleley", &ServiceInput{})
			So(err, ShouldEqual, ErrServiceNotFound)
		})

		Convey("it should able to return iterable service", func() {
			sf := NewServiceFactory()
			_, err := sf.Create("iterable", &ServiceInput{})
			So(err, ShouldBeNil)
		})
	})
}
