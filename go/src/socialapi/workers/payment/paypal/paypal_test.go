package paypal

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment/paymenterrors"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
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

	// CreateDefaultPlans()

	rand.Seed(time.Now().UTC().UnixNano())
}

func TestGetToken1(t *testing.T) {
	Convey("Given nonexistent plan", t, func() {
		_, err := GetToken("random_plans", "random_interval")

		Convey("Then it should throw error", func() {
			So(err, ShouldEqual, paymenterrors.ErrPlanNotFound)
		})
	})
}

func TestGetToken2(t *testing.T) {
	Convey("Given nonexistent customer, plan", t, func() {
		token, err := GetToken(StartingPlan, StartingInterval)

		Convey("Then it should return token", func() {
			So(err, ShouldBeNil)
			So(token, ShouldNotBeNil)
		})
	})
}
