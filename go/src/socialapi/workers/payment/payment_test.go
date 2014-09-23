package payment

import (
	"math/rand"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment/stripe"
	"strconv"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
	stripeClient "github.com/stripe/stripe-go"
	stripeToken "github.com/stripe/stripe-go/token"
)

var (
	FreePlan = "free"
)

func init() {
	r := runner.New("paymenttest")
	if err := r.Init(); err != nil {
		panic(err)
	}

	// init stripe client
	stripe.InitializeClientKey(config.MustGet().Stripe.SecretKey)

	rand.Seed(time.Now().UTC().UnixNano())
}

func TestSubscriptionsRequest(t *testing.T) {
	Convey("Given nonexistent user", t, func() {
		req := SubscriptionRequest{AccountId: "indianajones"}
		resp, err := req.Do()
		So(err, ShouldBeNil)

		Convey("Then it should return 'free' plan", func() {
			So(resp.PlanTitle, ShouldEqual, FreePlan)
		})
	})

	Convey("Given user subscribed to a plan", t, func() {
		err := stripe.CreateDefaultPlans()
		So(err, ShouldBeNil)

		token, accId, email := generateFakeUserInfo()
		err = stripe.Subscribe(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := stripe.FindCustomerByOldId(accId)
		So(err, ShouldBeNil)

		req := SubscriptionRequest{AccountId: customer.OldId}
		resp, err := req.Do()
		So(err, ShouldBeNil)

		Convey("Then it should return the plan", func() {
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

func generateFakeUserInfo() (string, string, string) {
	token, accId := createToken(), strconv.Itoa(rand.Int())
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

var (
	StartingPlan     = "developer"
	StartingInterval = "month"
)
