package payment

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/stripe"
	"testing"
	"time"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
	stripeClient "github.com/stripe/stripe-go"
	stripeToken "github.com/stripe/stripe-go/token"
)

func init() {
	r := runner.New("paymenttest")
	if err := r.Init(); err != nil {
		panic(err)
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	Initialize(config.MustGet())

	rand.Seed(time.Now().UTC().UnixNano())
}

func TestSubscriptionsRequest(t *testing.T) {
	Convey("Given nonexistent user", t, func() {
		req := AccountRequest{AccountId: "indianajones"}
		resp, err := req.Subscriptions()
		So(err, ShouldBeNil)

		Convey("Then it should return 'free' plan", func() {
			So(resp.PlanTitle, ShouldEqual, FreePlan)
		})
	})

	Convey("Given user subscribed to a plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := stripe.Subscribe(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := stripe.FindCustomerByOldId(accId)
		So(err, ShouldBeNil)

		Convey("When subscription is expired", func() {
			subscription, err := customer.FindActiveSubscription()
			So(err, ShouldBeNil)

			err = subscription.UpdateState(paymentmodels.SubscriptionStateExpired)
			So(err, ShouldBeNil)

			Convey("Then it should return the expired subscription", func() {
				req := AccountRequest{AccountId: customer.OldId}
				resp, err := req.Subscriptions()
				So(err, ShouldBeNil)

				So(resp.State, ShouldEqual, "expired")

				So(resp.PlanTitle, ShouldEqual, StartingPlan)
				So(resp.PlanInterval, ShouldEqual, StartingInterval)
			})
		})
	})

	Convey("Given user subscribed to a plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := stripe.Subscribe(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := stripe.FindCustomerByOldId(accId)
		So(err, ShouldBeNil)

		Convey("When subscription is canceled", func() {
			subscription, err := customer.FindActiveSubscription()
			So(err, ShouldBeNil)

			err = subscription.UpdateState(paymentmodels.SubscriptionStateCanceled)
			So(err, ShouldBeNil)

			Convey("Then it should return the free subscription", func() {
				req := AccountRequest{AccountId: customer.OldId}
				resp, err := req.Subscriptions()
				So(err, ShouldBeNil)

				So(resp.State, ShouldEqual, "active")

				So(resp.PlanTitle, ShouldEqual, FreePlan)
				So(resp.PlanInterval, ShouldEqual, FreeInterval)
			})
		})
	})

	Convey("Given user subscribed to a plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := stripe.Subscribe(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := stripe.FindCustomerByOldId(accId)
		So(err, ShouldBeNil)

		req := AccountRequest{AccountId: customer.OldId}
		resp, err := req.Subscriptions()
		So(err, ShouldBeNil)

		Convey("Then it should return the active subscription", func() {
			So(resp.CurrentPeriodStart.IsZero(), ShouldEqual, false)
			So(resp.CurrentPeriodEnd.IsZero(), ShouldEqual, false)
			So(resp.State, ShouldEqual, "active")

			So(resp.PlanTitle, ShouldEqual, StartingPlan)
			So(resp.PlanInterval, ShouldEqual, StartingInterval)
		})
	})
}

//----------------------------------------------------------
// Helpers
// TODO: move this to common place that stripe can use as well
//----------------------------------------------------------

var (
	FreePlan         = "free"
	FreeInterval     = "month"
	StartingPlan     = "developer"
	StartingInterval = "month"
)

func generateFakeUserInfo() (string, string, string) {
	token, accId := createToken(), bson.NewObjectId().Hex()
	email := accId + "@koding.com"

	return token, accId, email
}

func createToken() string {
	tokenParams := &stripeClient.TokenParams{
		Card: &stripeClient.CardParams{
			Number: "4242424242424242",
			Month:  "10",
			Year:   "20",
		},
	}

	token, err := stripeToken.New(tokenParams)
	if err != nil {
		panic(err)
	}

	return token.Id
}
