package stripe

import (
	"math/rand"
	"socialapi/workers/common/runner"
	"strconv"
	"time"

	"github.com/stripe/stripe-go"
	stripeCustomer "github.com/stripe/stripe-go/customer"
	stripeToken "github.com/stripe/stripe-go/token"
)

func init() {
	r := runner.New("stripetest")
	if err := r.Init(); err != nil {
		panic(err)
	}

	rand.Seed(time.Now().UTC().UnixNano())
}

func generateFakeUserInfo() (string, string, string) {
	token, accId := createToken(), strconv.Itoa(rand.Int())
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

	token, err := stripeToken.Create(tokenParams)
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
