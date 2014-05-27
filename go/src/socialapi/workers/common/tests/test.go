package tests

import . "github.com/smartystreets/goconvey/convey"

func ResultedWithNoErrorCheck(result interface{}, err error) {
	So(result, ShouldNotBeNil)
	So(err, ShouldBeNil)
}
