package payment

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/workers/payment/paymenterrors"
	"socialapi/workers/payment/paymentmodels"
	"socialapi/workers/payment/stripe"
	"testing"
	"time"

	"github.com/koding/runner"

	"gopkg.in/mgo.v2/bson"

	"github.com/koding/logging"
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
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	Initialize(config.MustGet())

	rand.Seed(time.Now().UTC().UnixNano())

	Log.SetLevel(logging.CRITICAL)
}

func TestGetAllCustomers(t *testing.T) {
	Convey("Given two actively subscribed users", t, func() {
		account := &models.Account{
			Id:      bson.NewObjectId(),
			Profile: models.AccountProfile{Nickname: "indianajones"},
		}
		err := modelhelper.CreateAccount(account)
		So(err, ShouldBeNil)

		accId := account.Id.Hex()

		token, _, email := generateFakeUserInfo()
		err = stripe.SubscribeForAccount(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		Convey("Then it should return their usernames", func() {
			req := AccountRequest{}
			usernames, err := req.ActiveUsernames()
			So(err, ShouldBeNil)

			So(len(usernames), ShouldBeGreaterThanOrEqualTo, 1)
			So(usernames, ShouldContain, "indianajones")
		})

		Reset(func() {
			modelhelper.RemoveAccount(account.Id)

			customer := paymentmodels.NewCustomer()
			customer.ByOldId(account.Id.Hex())

			subscription, _ := customer.FindActiveSubscription()
			subscription.Cancel()

			customer.DeleteSubscriptionsAndItself()
		})

	})
}

func TestExpireSubscription(t *testing.T) {
	Convey("Given user with active subscription", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := stripe.SubscribeForAccount(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		Convey("When request to expire subscription", func() {
			req := AccountRequest{AccountId: accId}
			_, err = req.Expire()
			So(err, ShouldBeNil)

			customer, err := paymentmodels.NewCustomer().ByOldId(req.AccountId)
			So(err, ShouldBeNil)

			Convey("Then it should expire subscription", func() {
				_, err = customer.FindActiveSubscription()
				So(err, ShouldEqual, paymenterrors.ErrCustomerNotSubscribedToAnyPlans)
			})
		})
	})
}

func TestSubscriptionsRequest1(t *testing.T) {
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
		err := stripe.SubscribeForAccount(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := paymentmodels.NewCustomer().ByOldId(accId)
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
		err := stripe.SubscribeForAccount(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := paymentmodels.NewCustomer().ByOldId(accId)
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
		err := stripe.SubscribeForAccount(
			token, accId, email, StartingPlan, StartingInterval,
		)
		So(err, ShouldBeNil)

		customer, err := paymentmodels.NewCustomer().ByOldId(accId)
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

func TestMultipleSubscriptionsRequest(t *testing.T) {
	Convey("Given user has multiple subscriptions", t, func() {
		token, accId, _ := generateFakeUserInfo()

		customer := &paymentmodels.Customer{
			OldId:              accId,
			Username:           accId,
			Provider:           stripe.ProviderName,
			ProviderCustomerId: token,
			TypeConstant:       paymentmodels.AccountCustomer,
		}
		So(customer.Create(), ShouldBeNil)

		plan := &paymentmodels.Plan{
			Title:          StartingPlan,
			Interval:       StartingInterval,
			Provider:       stripe.ProviderName,
			ProviderPlanId: token,
			TypeConstant:   paymentmodels.AccountCustomer,
		}
		So(plan.Create(), ShouldBeNil)

		sub1 := &paymentmodels.Subscription{
			PlanId:                 plan.Id,
			CustomerId:             customer.Id,
			State:                  "expired",
			Provider:               stripe.ProviderName,
			ProviderSubscriptionId: token,
		}
		So(sub1.Create(), ShouldBeNil)

		sub2 := &paymentmodels.Subscription{
			PlanId:                 plan.Id,
			CustomerId:             customer.Id,
			State:                  "active",
			Provider:               stripe.ProviderName,
			ProviderSubscriptionId: token + "1",
		}
		So(sub2.Create(), ShouldBeNil)

		Convey("Then it should return last subscription", func() {
			req := AccountRequest{AccountId: customer.OldId}
			resp, err := req.Subscriptions()
			So(err, ShouldBeNil)

			So(resp.State, ShouldEqual, "active")

			So(resp.PlanTitle, ShouldEqual, StartingPlan)
			So(resp.PlanInterval, ShouldEqual, StartingInterval)
		})
	})
}

func TestExpireOutofDateSubscriptions(t *testing.T) {
	Convey("Given subscriptions", t, func() {
		Convey("Then it should expire out of date subscriptions", func() {
			token, accId, email := generateFakeUserInfo()
			err := stripe.SubscribeForAccount(
				token, accId, email, StartingPlan, StartingInterval,
			)
			So(err, ShouldBeNil)

			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)

			subscription, err := customer.FindActiveSubscription()
			So(err, ShouldBeNil)
			So(subscription.State, ShouldEqual, paymentmodels.SubscriptionStateActive)

			err = subscription.UpdateToExpireTime(time.Now().Add(-1000 * time.Second))
			So(err, ShouldBeNil)

			err = ExpireOutofDateSubscriptions()
			So(err, ShouldBeNil)

			_, err = customer.FindActiveSubscription()
			So(err, ShouldEqual, paymenterrors.ErrCustomerNotSubscribedToAnyPlans)
		})

		Convey("Then it shouldn't expire active subscriptions", func() {
			token, accId, email := generateFakeUserInfo()
			err := stripe.SubscribeForAccount(
				token, accId, email, StartingPlan, StartingInterval,
			)
			So(err, ShouldBeNil)

			customer, err := paymentmodels.NewCustomer().ByOldId(accId)
			So(err, ShouldBeNil)

			err = ExpireOutofDateSubscriptions()
			So(err, ShouldBeNil)

			subscription, err := customer.FindActiveSubscription()
			So(err, ShouldBeNil)
			So(subscription.State, ShouldEqual, paymentmodels.SubscriptionStateActive)
		})
	})
}

//----------------------------------------------------------
// Helpers
// TODO: move this to common place that stripe can use as well
//----------------------------------------------------------

var (
	FreePlan              = "free"
	FreeInterval          = "month"
	StartingPlan          = "developer"
	StartingInterval      = "month"
	GroupStartingPlan     = "startup"
	GroupStartingInterval = "month"
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
