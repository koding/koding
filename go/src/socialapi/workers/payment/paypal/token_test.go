package paypal

import (
	"socialapi/workers/payment/paymenterrors"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetToken1(t *testing.T) {
	Convey("Given nonexistent plan", t, func() {
		_, err := GetToken("random_plans", "random_interval")

		Convey("Then it should throw error", func() {
			So(err, ShouldEqual, paymenterrors.ErrPlanNotFound)
		})
	})
}

func TestGetToken2(t *testing.T) {
	Convey("Given nonexistent customer, plan", t, func() {
		token, err := GetToken(StartingPlan, StartingInterval)

		Convey("Then it should return token", func() {
			So(err, ShouldBeNil)
			So(token, ShouldNotBeNil)
		})
	})
}
