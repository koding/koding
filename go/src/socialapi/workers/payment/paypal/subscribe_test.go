package paypal

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"socialapi/workers/payment/paymenterrors"
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

func TestSubscribe2(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintln(w, `&paypal.PayPalResponse{
    Ack:           "Success",
    CorrelationId: "9d9643d288fd8",
    Timestamp:     "2014-10-30T17:55:11Z",
    Version:       "84",
    Build:         "",
    Values:        {
        "VERSION":       {"84"},
        "BUILD":         {"13562569"},
        "PROFILEID":     {"I-M6HJ6NGU8TWH"},
        "PROFILESTATUS": {"ActiveProfile"},
        "TIMESTAMP":     {"2014-10-30T17:55:11Z"},
        "CORRELATIONID": {"9d9643d288fd8"},
        "ACK":           {"Success"},
    },
    usedSandbox: true,
}`)
		},
	))

	defer server.Close()

	client = paypal.NewDefaultClientEndpoint(
		username, password, signature, server.URL, isSandbox,
	)

	Convey("Given nonexistent customer, plan", t,
		subscribeFn(func(token, accId, email string) {
			customerModel, err := FindCustomerByOldId(accId)

			So(err, ShouldBeNil)
			So(customerModel, ShouldNotBeNil)

			Convey("Then it should save customer", func() {
				So(checkCustomerIsSaved(accId), ShouldBeTrue)
			})
		}),
	)
}
