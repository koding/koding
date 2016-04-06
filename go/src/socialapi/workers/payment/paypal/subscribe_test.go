package paypal

import (
	"socialapi/workers/payment/paymenterrors"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestSubscribe(t *testing.T) {
	server := startTestServer()
	defer server.Close()

	Convey("Given nonexistent customer, plan", t, func() {
		token, accId, _ := generateFakeUserInfo()
		err := Subscribe(token, accId)

		So(err, ShouldEqual, paymenterrors.ErrNotImplemented)
	})
}
