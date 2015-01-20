package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestExempt(t *testing.T) {
	Convey("Given exempt users", t, func() {
		Convey("Then it should save them", func() {
			saveExemptUsers()

			Convey("Then it get them", func() {
				metricName := metricsToSave[0].GetName()

				exemptUser, ok := ExemptUsers[0].(string)
				So(ok, ShouldBeTrue)

				yes, err := exemptFromStopping(metricName, exemptUser)
				So(err, ShouldBeNil)

				So(yes, ShouldBeTrue)
			})
		})
	})
}
