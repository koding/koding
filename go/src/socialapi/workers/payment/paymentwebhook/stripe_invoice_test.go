package main

import (
	"socialapi/workers/payment/paymentwebhook/webhookmodels"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestStripeInvoiceGetPlanName(t *testing.T) {
	Convey("Given invoice webhook from stripe", t, func() {
		Convey("When no line item data", func() {
			Convey("Then it should return err", func() {
				invoice := raw_no_lineitems_invoice()
				_, err := getNewPlanName(invoice)

				So(err, ShouldNotBeNil)
			})
		})

		Convey("When empty line items", func() {
			Convey("Then it should return err", func() {
				invoice := raw_empty_lineitems_invoice()
				_, err := getNewPlanName(invoice)

				So(err, ShouldNotBeNil)
			})
		})

		Convey("When 1 line items", func() {
			Convey("Then it should return plan name of 1st item", func() {
				invoice := rawOneLineitemsInvoice()
				planName, err := getNewPlanName(invoice)

				So(err, ShouldBeNil)
				So(planName, ShouldEqual, "Pla_000")
			})
		})

		Convey("When 2 line items", func() {
			Convey("Then it should return plan name of 2nd item", func() {
				invoice := rawTwoLineitemsInvoice()
				planName, err := getNewPlanName(invoice)

				So(err, ShouldBeNil)
				So(planName, ShouldEqual, "Pla_001")
			})
		})
	})
}

func raw_no_lineitems_invoice() *webhookmodels.StripeInvoice {
	return &webhookmodels.StripeInvoice{
		ID:         "evt_15rcA7Dy8g9bkw8y4opMBcgB",
		CustomerId: "cus_61nef0wiQMSCGY",
		AmountDue:  0,
		Currency:   "usd",
		Lines: webhookmodels.StripeInvoiceLines{
			Count: 0,
			Data:  nil,
		},
	}
}

func raw_empty_lineitems_invoice() *webhookmodels.StripeInvoice {
	return &webhookmodels.StripeInvoice{
		ID:         "evt_15rcA7Dy8g9bkw8y4opMBcgB",
		CustomerId: "cus_61nef0wiQMSCGY",
		AmountDue:  0,
		Currency:   "usd",
		Lines: webhookmodels.StripeInvoiceLines{
			Count: 0,
			Data:  []webhookmodels.StripeInvoiceData{},
		},
	}
}

func rawOneLineitemsInvoice() *webhookmodels.StripeInvoice {
	return &webhookmodels.StripeInvoice{
		ID:         "ID_000",
		CustomerId: "Cus_000",
		AmountDue:  0,
		Currency:   "usd",
		Lines: webhookmodels.StripeInvoiceLines{
			Count: 1,
			Data: []webhookmodels.StripeInvoiceData{
				webhookmodels.StripeInvoiceData{
					SubscriptionId: "Sub_000",
					Plan: webhookmodels.StripePlan{
						Name: "Pla_000",
					},
				},
			},
		},
	}
}

func rawTwoLineitemsInvoice() *webhookmodels.StripeInvoice {
	return &webhookmodels.StripeInvoice{
		ID:         "evt_15rcA7Dy8g9bkw8y4opMBcgB",
		CustomerId: "cus_61nef0wiQMSCGY",
		AmountDue:  0,
		Currency:   "usd",
		Lines: webhookmodels.StripeInvoiceLines{
			Count: 2,
			Data: []webhookmodels.StripeInvoiceData{
				webhookmodels.StripeInvoiceData{
					SubscriptionId: "Sub_000",
					Plan: webhookmodels.StripePlan{
						Name: "Pla_000",
					},
				},
				webhookmodels.StripeInvoiceData{
					SubscriptionId: "Sub_001",
					Plan: webhookmodels.StripePlan{
						Name: "Pla_001",
					},
				},
			},
		},
	}
}
