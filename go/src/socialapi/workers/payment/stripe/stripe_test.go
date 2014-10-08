package stripe

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment/paymentmodels"
	"time"

	"labix.org/v2/mgo/bson"

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

	// init stripe client
	InitializeClientKey(config.MustGet().Stripe.SecretToken)

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

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
	customerModel, err := FindCustomerByOldId(accId)
	if err != nil {
		return false
	}

	if customerModel == nil {
		return false
	}

	if customerModel.OldId != accId {
		return false
	}

	return true
}

func checkCustomerExistsInStripe(id string) bool {
	customer, err := stripeCustomer.Get(id, nil)
	if err != nil {
		return false
	}

	if customer.Id != id {
		return false
	}

	return true
}

func createCustomerFn(fn func(string, *paymentmodel.Customer)) func() {
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
		err := Subscribe(token, accId, email, StartingPlan, StartingInterval)

		So(err, ShouldBeNil)

		fn(token, accId, email)
	}
}

func existingSubscribeFn(fn func(string, string, string)) func() {
	return func() {
		token, accId, email := generateFakeUserInfo()

		_, err := CreateCustomer(token, accId, email)
		So(err, ShouldBeNil)

		err = Subscribe(token, accId, email, StartingPlan, StartingInterval)
		So(err, ShouldBeNil)

		fn(token, accId, email)
	}
}
