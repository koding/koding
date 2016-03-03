package stripe

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/workers/payment/paymentmodels"
	"time"

	"github.com/koding/runner"

	"gopkg.in/mgo.v2/bson"

	"github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
	stripeToken "github.com/stripe/stripe-go/token"

	. "github.com/smartystreets/goconvey/convey"
)

func init() {
	r := runner.New("stripetest")
	if err := r.Init(); err != nil {
		panic(err)
	}

	appConfig := config.MustRead(r.Conf.Path)

	// init stripe client
	InitializeClientKey(appConfig.Stripe.SecretToken)

	modelhelper.Initialize(appConfig.Mongo)

	CreateDefaultPlans()

	rand.Seed(time.Now().UTC().UnixNano())
}

var (
	StartingPlan      = "developer"
	StartingInterval  = "month"
	StartingPlanPrice = 2450
	HigherPlan        = "professional"
	HigherInterval    = "month"
	LowerPlan         = "hobbyist"
	LowerInterval     = "month"
	FreePlan          = "free"
	FreeInterval      = "month"

	GroupStartingPlan = "startup"
	GroupHigherPlan   = "enterprise"
	GroupLowerPlan    = "boostrap"
	GroupInterval     = "month"

	LowerPlanProviderId = "hobbyist_month"
)

func generateFakeUserInfo() (string, string, string) {
	token, accId := createToken(), bson.NewObjectId().Hex()
	email := accId + "@koding.com"

	return token, accId, email
}

func createToken() string {
	tokenParams := &stripe.TokenParams{
		Card: &stripe.CardParams{
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

func checkCustomerIsSaved(accId string) bool {
	customer, err := paymentmodels.NewCustomer().ByOldId(accId)
	if err != nil {
		return false
	}

	if customer == nil {
		return false
	}

	if customer.OldId != accId {
		return false
	}

	return true
}

func checkCustomerExistsInStripe(id string) bool {
	customer, err := stripeCustomer.Get(id, nil)
	if err != nil || customer.Id != id {
		return false
	}

	return true
}

func createCustomerFn(fn func(string, *paymentmodels.Customer)) func() {
	return func() {
		token, accId, email := generateFakeUserInfo()

		customer, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		fn(accId, customer)
	}
}

func subscribeFn(fn func(string, string, string)) func() {
	return func() {
		token, accId, email := generateFakeUserInfo()
		err := SubscribeForAccount(token, accId, email, StartingPlan, StartingInterval)

		So(err, ShouldBeNil)

		fn(token, accId, email)
	}
}

func existingSubscribeFn(fn func(string, string, string)) func() {
	return func() {
		token, accId, email := generateFakeUserInfo()

		_, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		token, _, _ = generateFakeUserInfo()

		err = SubscribeForAccount(token, accId, email, StartingPlan, StartingInterval)
		So(err, ShouldBeNil)

		fn(token, accId, email)
	}
}

func subscribeWithReturnsFn(fn func(*paymentmodels.Customer, *paymentmodels.Subscription)) func() {
	return func() {
		token, accId, email := generateFakeUserInfo()

		err := SubscribeForAccount(token, accId, email, StartingPlan, StartingInterval)
		So(err, ShouldBeNil)

		customer, err := paymentmodels.NewCustomer().ByOldId(accId)
		So(err, ShouldBeNil)

		subscription, err := customer.FindActiveSubscription()
		So(err, ShouldBeNil)

		fn(customer, subscription)
	}
}

///// Group

func subscribeGroupFn(fn func(string, string, string)) func() {
	return func() {
		token, gId, email := generateFakeUserInfo()
		group := &models.Group{
			Id:   bson.ObjectIdHex(gId),
			Slug: token[0:23],
		}
		err := modelhelper.CreateGroup(group)
		So(err, ShouldBeNil)

		err = SubscribeForGroup(token, gId, email, GroupStartingPlan, GroupInterval)
		So(err, ShouldBeNil)

		fn(token, gId, email)
	}
}
