package stripe

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetInvoice(t *testing.T) {
	Convey("Given a subscribed user", t, func() {
		token, accId, email := generateFakeUserInfo()
		err := Subscribe(token, accId, email, StartingPlan, StartingInterval)

		So(err, ShouldBeNil)

		Convey("Then it should return list of invoices for the user", func() {
			invoices, err := FindInvoicesForCustomer(accId)
			So(err, ShouldBeNil)

			So(len(invoices), ShouldEqual, 1)

			firstInvoice := invoices[0]
			So(firstInvoice.PeriodStart.IsZero(), ShouldBeFalse)
			So(firstInvoice.PeriodEnd.IsZero(), ShouldBeFalse)
			So(firstInvoice.Amount, ShouldEqual, StartingPlanPrice)
		})
	})
}
