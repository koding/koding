package paypal

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/workers/common/runner"
	"socialapi/workers/payment/stripe"
	"strconv"
	"time"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
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

func generateFakeUserInfo() (string, string, string) {
	token, accId := strconv.Itoa(rand.Int()), bson.NewObjectId().Hex()
	email := accId + "@koding.com"

	return token, accId, email
}

func subscribeFn(fn func(string, string, string)) func() {
	return func() {
		token, accId, email := generateFakeUserInfo()
		err := Subscribe(token, accId, email)

		So(err, ShouldBeNil)

		fn(token, accId, email)
	}
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
