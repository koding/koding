package webhookmodels

import (
	"encoding/json"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

var subscriptionCreatedWebhookRequest = []byte(`{
      "id": "sub_00000000000000",
      "plan": {
        "interval": "year",
        "name": "Developer",
        "created": 1412968872,
        "amount": 23940,
        "currency": "usd",
        "id": "developer_00000000000000",
        "object": "plan",
        "livemode": false,
        "interval_count": 1,
        "trial_period_days": null,
        "metadata": {},
        "statement_descriptor": null,
        "statement_description": null
      },
      "object": "subscription",
      "start": 1422577711,
      "status": "active",
      "customer": "cus_00000000000000",
      "cancel_at_period_end": false,
      "current_period_start": 1422577711,
      "current_period_end": 1454113711,
      "ended_at": null,
      "trial_start": null,
      "trial_end": null,
      "canceled_at": null,
      "quantity": 1,
      "application_fee_percent": null,
      "discount": null,
      "tax_percent": null,
      "metadata": {}
    }
`)

var invoiceCreatedWebhookRequest = []byte(`{
		"date": 1422578141,
		"id": "in_00000000000000",
		"period_start": 1422578141,
		"period_end": 1422578141,
		"lines": {
			"data": [
				{
					"id": "sub_5bg7lgPIPCWEI3",
					"object": "line_item",
					"type": "subscription",
					"livemode": true,
					"amount": 23940,
					"currency": "usd",
					"proration": false,
					"period": {
						"start": 1454114143,
						"end": 1485736543
					},
					"subscription": null,
					"quantity": 1,
					"plan": {
						"interval": "year",
						"name": "Developer",
						"created": 1412968872,
						"amount": 23940,
						"currency": "usd",
						"id": "developer_year",
						"object": "plan",
						"livemode": false,
						"interval_count": 1,
						"trial_period_days": null,
						"metadata": {},
						"statement_descriptor": null,
						"statement_description": null
					},
					"description": null,
					"metadata": {}
				}
			],
			"total_count": 1,
			"object": "list",
			"url": "/v1/invoices/in_15QSl7Dy8g9bkw8yWuzjCCA0/lines"
		},
		"subtotal": 2450,
		"total": 2450,
		"customer": "cus_00000000000000",
		"object": "invoice",
		"attempted": false,
		"closed": true,
		"forgiven": false,
		"paid": true,
		"livemode": false,
		"attempt_count": 1,
		"amount_due": 2450,
		"currency": "usd",
		"starting_balance": 0,
		"ending_balance": 0,
		"next_payment_attempt": null,
		"webhooks_delivered_at": null,
		"charge": "ch_00000000000000",
		"discount": null,
		"application_fee": null,
		"subscription": "sub_00000000000000",
		"tax_percent": null,
		"metadata": {},
		"statement_descriptor": null,
		"description": null,
		"receipt_number": null,
		"statement_description": null
	}`)

func TestStripe(t *testing.T) {
	Convey("Given webhook from stripe", t, func() {
		Convey("Then it should unmarshal subscription", func() {
			var sub *StripeSubscription
			err := json.Unmarshal(subscriptionCreatedWebhookRequest, &sub)

			So(err, ShouldBeNil)

			So(sub.ID, ShouldEqual, "sub_00000000000000")
			So(sub.CustomerId, ShouldEqual, "cus_00000000000000")
			So(sub.Plan.ID, ShouldEqual, "developer_00000000000000")
			So(sub.Plan.Name, ShouldEqual, "Developer")
		})

		Convey("Then it should unmarshal invoice", func() {
			var invoice *StripeInvoice
			err := json.Unmarshal(invoiceCreatedWebhookRequest, &invoice)

			So(err, ShouldBeNil)

			So(invoice.ID, ShouldEqual, "in_00000000000000")
			So(invoice.CustomerId, ShouldEqual, "cus_00000000000000")
			So(invoice.AmountDue, ShouldEqual, 2450)
			So(invoice.Currency, ShouldEqual, "usd")
			So(invoice.Lines.Count, ShouldEqual, 1)
			So(len(invoice.Lines.Data), ShouldEqual, 1)

			data := invoice.Lines.Data[0]

			So(data.SubscriptionId, ShouldEqual, "sub_5bg7lgPIPCWEI3")
			So(data.Period.Start, ShouldEqual, 1454114143)
			So(data.Period.End, ShouldEqual, 1485736543)
			So(data.Plan.Name, ShouldEqual, "Developer")
			So(data.Plan.Interval, ShouldEqual, "year")
		})
	})
}
