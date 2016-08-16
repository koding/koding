package payment

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetInvoice(t *testing.T) {
	Convey("Given a subscribed user", t, nil) // subscribeFn(func(token, accId, email string) {
	// 	Convey("Then it should return list of invoices for the user", func() {
	// invoices, err := FindInvoicesForCustomer(accId)
	// So(err, ShouldBeNil)

	// So(len(invoices), ShouldEqual, 1)

	// firstInvoice := invoices[0]
	// So(firstInvoice.PeriodStart.IsZero(), ShouldBeFalse)
	// So(firstInvoice.PeriodEnd.IsZero(), ShouldBeFalse)
	// So(firstInvoice.Amount, ShouldEqual, StartingPlanPrice)

	// ccResp := firstInvoice.CreditCardResponse

	// So(ccResp, ShouldNotBeNil)
	// So(ccResp.LastFour, ShouldEqual, "4242")
	// 		})
	// }),

}
