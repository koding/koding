package payment

import (
	"encoding/json"
	"fmt"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"github.com/stripe/stripe-go"
)

func TestCouponApply(t *testing.T) {
	Convey("Given a user", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestCoupon(func(couponID string) {
					updateUrl := fmt.Sprintf("%s/payment/customer/update", endpoint)

					cp := &stripe.CustomerParams{
						Coupon: couponID,
					}

					req, err := json.Marshal(cp)
					So(err, ShouldBeNil)
					So(req, ShouldNotBeNil)

					res, err := rest.DoRequestWithAuth("POST", updateUrl, req, sessionID)
					So(err, ShouldBeNil)
					So(res, ShouldNotBeNil)

					v := &stripe.Customer{}
					err = json.Unmarshal(res, v)
					So(err, ShouldBeNil)

					So(v.Discount, ShouldNotBeNil)
					So(v.Discount.Coupon.ID, ShouldEqual, couponID)
					So(v.Discount.Coupon.Valid, ShouldBeTrue)
					So(v.Discount.Coupon.Deleted, ShouldBeFalse)
				})
			})
		})
	})
}
