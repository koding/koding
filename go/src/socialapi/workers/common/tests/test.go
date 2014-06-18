package tests

import . "github.com/smartystreets/goconvey/convey"

func ResultedWithNoErrorCheck(result interface{}, err error) {
	So(err, ShouldBeNil)
	So(result, ShouldNotBeNil)
}
