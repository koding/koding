package payment

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/stripe"
)

func TestGroupSubscriptions(t *testing.T) {
	Convey("Given group with no subscription", t, func() {
		req := GroupRequest{GroupId: "groupid"}
		resp, err := req.Subscriptions()
		So(err, ShouldBeNil)

		Convey("Then it should return 'free' plan", func() {
			So(resp.PlanTitle, ShouldEqual, FreePlan)
		})
	})

	Convey("Given group with subscription", t, func() {
		token, groupId, email := generateFakeUserInfo()
		err := stripe.SubscribeForGroup(
			token, groupId, email, GroupStartingPlan, GroupStartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := paymentmodels.NewCustomer().ByOldId(groupId)
		So(err, ShouldBeNil)

		subscription, err := customer.FindActiveSubscription()
		So(err, ShouldBeNil)

		Convey("When subscription is expired", func() {
			err = subscription.UpdateState(paymentmodels.SubscriptionStateExpired)
			So(err, ShouldBeNil)

			Convey("Then it should return the expired subscription", func() {
				req := GroupRequest{GroupId: groupId}
				resp, err := req.Subscriptions()
				So(err, ShouldBeNil)

				So(resp.PlanTitle, ShouldEqual, GroupStartingPlan)
				So(resp.State, ShouldEqual, "expired")
			})
		})

		Convey("When subscription is canceled", func() {
			err = subscription.UpdateState(paymentmodels.SubscriptionStateCanceled)
			So(err, ShouldBeNil)

			Convey("Then it should return the free subscription", func() {
				req := GroupRequest{GroupId: groupId}
				resp, err := req.Subscriptions()
				So(err, ShouldBeNil)

				So(resp.State, ShouldEqual, "active")

				So(resp.PlanTitle, ShouldEqual, FreePlan)
				So(resp.PlanInterval, ShouldEqual, FreeInterval)
			})
		})

		Convey("When subscription is active", func() {
			Convey("Then it should return the subscription", func() {
				req := GroupRequest{GroupId: groupId}
				resp, err := req.Subscriptions()
				So(err, ShouldBeNil)

				So(resp.PlanTitle, ShouldEqual, GroupStartingPlan)
				So(resp.State, ShouldEqual, "active")
			})
		})
	})
}

func TestGroupDeleteCustomer(t *testing.T) {
	Convey("Given group with subscription", t, func() {
		token, groupId, email := generateFakeUserInfo()
		err := stripe.SubscribeForGroup(
			token, groupId, email, GroupStartingPlan, GroupStartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := paymentmodels.NewCustomer().ByOldId(groupId)
		So(err, ShouldBeNil)

		_, err = customer.FindActiveSubscription()
		So(err, ShouldBeNil)

		Convey("Then it should delete subscription", func() {
			req := GroupRequest{GroupId: groupId}
			_, err := req.Delete()
			So(err, ShouldBeNil)

			_, err = customer.FindActiveSubscription()
			So(err, ShouldEqual, paymenterrors.ErrCustomerNotSubscribedToAnyPlans)
		})
	})
}

func TestGroupGetCreditCard(t *testing.T) {
	Convey("Given group with subscription", t, func() {
		token, groupId, email := generateFakeUserInfo()
		err := stripe.SubscribeForGroup(
			token, groupId, email, GroupStartingPlan, GroupStartingInterval,
		)
		So(err, ShouldBeNil)

		Convey("Then it should return credit card", func() {
			req := GroupRequest{GroupId: groupId}
			resp, err := req.GetCreditCard()
			So(err, ShouldBeNil)

			So(resp.LastFour, ShouldEqual, "4242")
		})
	})
}

func TestGroupGetInvoices(t *testing.T) {
	Convey("Given group with subscription", t, func() {
		token, groupId, email := generateFakeUserInfo()
		err := stripe.SubscribeForGroup(
			token, groupId, email, GroupStartingPlan, GroupStartingInterval,
		)
		So(err, ShouldBeNil)

		Convey("Then it should return invoices", func() {
			req := GroupRequest{GroupId: groupId}
			resp, err := req.GetInvoices()
			So(err, ShouldBeNil)

			So(len(resp), ShouldEqual, 1)
		})
	})
}
