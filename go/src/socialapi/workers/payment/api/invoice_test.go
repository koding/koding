package api

import (
	"encoding/json"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	. "github.com/smartystreets/goconvey/convey"

	stripe "github.com/stripe/stripe-go"
)

func TestInvoiceList(t *testing.T) {
	Convey("Given stub data", t, func() {
		withTestServer(t, func(endpoint string) {
			withStubData(endpoint, func(username, groupName, sessionID string) {
				withTestPlan(func(planID string) {
					createUrl := fmt.Sprintf("%s/payment/subscription/create", endpoint)
					deleteUrl := fmt.Sprintf("%s/payment/subscription/delete", endpoint)

					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					Convey("We should be able to create a subscription", func() {
						req, err := json.Marshal(&stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     planID,
						})
						tests.ResultedWithNoErrorCheck(req, err)

						res, err := rest.DoRequestWithAuth("POST", createUrl, req, sessionID)
						tests.ResultedWithNoErrorCheck(res, err)

						v := &stripe.Sub{}
						err = json.Unmarshal(res, v)
						So(err, ShouldBeNil)
						So(v.Status, ShouldEqual, "active")

						Convey("We should be able to list invoices", func() {
							listInvoicesUrl := fmt.Sprintf("%s/payment/invoice/list", endpoint)

							res, err = rest.DoRequestWithAuth("GET", listInvoicesUrl, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							var invoices []*stripe.Invoice
							err = json.Unmarshal(res, &invoices)
							So(err, ShouldBeNil)
							So(len(invoices), ShouldBeGreaterThan, 0)
							Convey("We should be able to list invoices with startingAfter query param", func() {
								listInvoicesUrlWithQuery := fmt.Sprintf("%s/payment/invoice/list?startingAfter=%s", endpoint, invoices[0].ID)

								res, err = rest.DoRequestWithAuth("GET", listInvoicesUrlWithQuery, nil, sessionID)
								tests.ResultedWithNoErrorCheck(res, err)

								var invoices []*stripe.Invoice
								err = json.Unmarshal(res, &invoices)
								So(err, ShouldBeNil)
								So(len(invoices), ShouldEqual, 0) // because we only have one invoice

								Convey("We should be able to cancel the subscription", func() {
									res, err = rest.DoRequestWithAuth("DELETE", deleteUrl, req, sessionID)
									tests.ResultedWithNoErrorCheck(res, err)
								})
							})
						})
					})
				})
			})
		})
	})
}
