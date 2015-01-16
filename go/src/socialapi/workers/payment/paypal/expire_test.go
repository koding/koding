package paypal

import (
	"socialapi/workers/payment/paymentmodels"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestExpire1(t *testing.T) {
	server := startTestServer()
	defer server.Close()

	Convey("Given active subscription", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := FindCustomerByOldId(accId)

			So(err, ShouldBeNil)
			So(customer, ShouldNotBeNil)

			Convey("When request comes to expire subsciprtion", func() {
				err := ExpireSubscription(customer.ProviderCustomerId)
				So(err, ShouldBeNil)

				Convey("Then it should expire subscription", func() {
					subs, err := customer.FindSubscriptions()
					So(err, ShouldBeNil)
					So(len(subs), ShouldEqual, 1)

					sub := subs[0]

					So(sub.State, ShouldEqual, paymentmodels.SubscriptionStateExpired)
				})
			})
		}),
	)
}
