package paypal

import (
	"socialapi/workers/payment/paymentmodels"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestSubscribe1(t *testing.T) {
	server := startTestServer()
	defer server.Close()

	Convey("Given nonexistent customer, plan", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)

			So(err, ShouldBeNil)
			So(customer, ShouldNotBeNil)

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(accId), ShouldBeTrue)
			})

			Convey("Then it should save subscription", func() {
				sub, err := customer.FindActiveSubscription()

				So(err, ShouldBeNil)
				So(sub, ShouldNotBeNil)
			})
		}),
	)
}

func TestSubscribe2(t *testing.T) {
	server := startTestServer()
	defer server.Close()

	Convey("Given customer with not active subscription", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)

			So(err, ShouldBeNil)
			So(customer, ShouldNotBeNil)

			err = ExpireSubscription(customer.ProviderCustomerId)
			So(err, ShouldBeNil)

			Convey("When customer subscribes again", func() {
				err = Subscribe(token, accId)
				So(err, ShouldBeNil)

				Convey("Then it should create new customer", func() {
					So(checkCustomerIsSaved(accId), ShouldBeTrue)
				})

				Convey("Then it should save subscription", func() {
					sub, err := customer.FindActiveSubscription()

					So(err, ShouldBeNil)
					So(sub, ShouldNotBeNil)
				})
			})
		}),
	)
}

func TestSubscribe3(t *testing.T) {
	server := startTestServer()
	defer server.Close()

	Convey("Given customer with not active subscription", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)
			So(customer, ShouldNotBeNil)

			err = ExpireSubscription(customer.ProviderCustomerId)
			So(err, ShouldBeNil)

			err = Subscribe(token, accId)
			So(err, ShouldBeNil)

			customer, err = paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)

			sub, err := customer.FindActiveSubscription()
			So(err, ShouldBeNil)
			So(sub, ShouldNotBeNil)
		}),
	)
}
