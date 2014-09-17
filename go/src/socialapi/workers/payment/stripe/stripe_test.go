package stripe

import (
	"math/rand"
	"socialapi/workers/common/runner"
	"strconv"

	"github.com/stripe/stripe-go"
	stripeToken "github.com/stripe/stripe-go/token"
)

func init() {
	r := runner.New("stripetest")
	if err := r.Init(); err != nil {
		panic(err)
	}
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
