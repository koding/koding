package paypal

import (
	"math/rand"
	"net/http"
	"net/http/httptest"
	"net/url"
	"socialapi/workers/payment/paymenterrors"
	"strconv"
	"testing"

	"github.com/koding/paypal"
	. "github.com/smartystreets/goconvey/convey"
)

func TestSubscribe1(t *testing.T) {
	Convey("Given nonexistent plan", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := Subscribe(token, accId, email, "random_plans", "random_interval")

		Convey("Then it should throw error", func() {
			So(err, ShouldEqual, paymenterrors.ErrPlanNotFound)
		})
	})
}

func subscribeResponse() []byte {
	profileId := strconv.Itoa(rand.Int())

	values := url.Values{}
	values.Set("ACK", "Success")
	values.Set("BUILD", "13630372")
	values.Set("CORRELATIONID", "7f7363b7c00fa")
	values.Set("PROFILEID", profileId)
	values.Set("PROFILESTATUS", "ActiveProfile")
	values.Set("TIMESTAMP", "2014-11-04T23:18:28Z")
	values.Set("VERSION", "84")

	return []byte(values.Encode())
}

func TestSubscribe2(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			w.Write(subscribeResponse())
		},
	))

	defer server.Close()

	client = paypal.NewDefaultClientEndpoint(
		username, password, signature, server.URL, isSandbox,
	)

	Convey("Given nonexistent customer, plan", t,
		subscribeFn(func(token, accId, email string) {
			customer, err := FindCustomerByOldId(accId)

			So(err, ShouldBeNil)
			So(customer, ShouldNotBeNil)

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(accId), ShouldBeTrue)
			})

			Convey("Then it should save subscription", func() {
				sub, err := customer.FindActiveSubscription()

				So(err, ShouldBeNil)
				So(sub, ShouldNotBeNil)
			})
		}),
	)
}
