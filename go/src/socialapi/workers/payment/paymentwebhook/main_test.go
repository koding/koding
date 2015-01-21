package main

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func init() {
	r := runner.New("paymenttest")
	if err := r.Init(); err != nil {
		panic(err)
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	payment.Initialize(config.MustGet(), r.Kite)

	rand.Seed(time.Now().UTC().UnixNano())
}

func TestStripe(t *testing.T) {
	Convey("Given webhook from stripe", t, func() {
		Convey("When it's 'customer.created'", func() {
		})
	})
}
