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
					createURL := endpoint + EndpointSubscriptionCreate
					deleteURL := endpoint + EndpointSubscriptionCancel

					group, err := modelhelper.GetGroup(groupName)
					tests.ResultedWithNoErrorCheck(group, err)

					addCreditCardToUserWithChecks(endpoint, sessionID)

					Convey("We should be able to create a subscription", func() {
						req, err := json.Marshal(&stripe.SubParams{
							Customer: group.Payment.Customer.ID,
							Plan:     planID,
						})
						tests.ResultedWithNoErrorCheck(req, err)

						res, err := rest.DoRequestWithAuth("POST", createURL, req, sessionID)
						tests.ResultedWithNoErrorCheck(res, err)

						v := &stripe.Sub{}
						err = json.Unmarshal(res, v)
						So(err, ShouldBeNil)
						So(v.Status, ShouldEqual, "active")

						Convey("We should be able to list invoices", func() {
							listInvoicesURL := endpoint + EndpointInvoiceList
							res, err = rest.DoRequestWithAuth("GET", listInvoicesURL, nil, sessionID)
							tests.ResultedWithNoErrorCheck(res, err)

							var invoices []*stripe.Invoice
							err = json.Unmarshal(res, &invoices)
							So(err, ShouldBeNil)
							So(len(invoices), ShouldBeGreaterThan, 0)
							Convey("We should be able to list invoices with startingAfter query param", func() {
								listInvoicesURLWithQuery := fmt.Sprintf("%s%s?startingAfter=%s", endpoint, EndpointInvoiceList, invoices[0].ID)
								res, err = rest.DoRequestWithAuth("GET", listInvoicesURLWithQuery, nil, sessionID)
								tests.ResultedWithNoErrorCheck(res, err)

								var invoices []*stripe.Invoice
								err = json.Unmarshal(res, &invoices)
								So(err, ShouldBeNil)
								So(len(invoices), ShouldEqual, 0) // because we only have one invoice

								Convey("We should be able to cancel the subscription", func() {
									res, err = rest.DoRequestWithAuth("DELETE", deleteURL, req, sessionID)
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
