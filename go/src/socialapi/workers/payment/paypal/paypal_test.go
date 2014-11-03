package paypal

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment/stripe"
	"time"
)

var (
	StartingPlan     = "developer"
	StartingInterval = "month"
)

func init() {
	r := runner.New("paypaltest")
	if err := r.Init(); err != nil {
		panic(err)
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	stripe.CreateDefaultPlans()

	rand.Seed(time.Now().UTC().UnixNano())
}
