package paypal

import (
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetToken1(t *testing.T) {
	server := startTestServer()
	defer server.Close()

	Convey("Given nonexistent plan", t, func() {
		_, err := GetToken("random_plans", "random_interval", paymentmodels.AccountCustomer)

		Convey("Then it should throw error", func() {
			So(err, ShouldEqual, paymenterrors.ErrPlanNotFound)
		})
	})
}

func TestGetToken2(t *testing.T) {
	server := startTestServer()
	defer server.Close()

	Convey("Given nonexistent customer, plan", t, func() {
		token, err := GetToken(StartingPlan, StartingInterval, paymentmodels.AccountCustomer)

		Convey("Then it should return token", func() {
			So(err, ShouldBeNil)
			So(token, ShouldNotBeNil)
		})
	})
}
