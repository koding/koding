package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	//----------------------------------------------------------
	// Subscribe
	//----------------------------------------------------------

	// this is same /payments/account/subscribe, here for backwards compatibilty
	m.AddHandler(
		handler.Request{
			Handler:  AccountSubscribe,
			Name:     "payment-subsrcibe",
			Type:     handler.PostRequest,
			Endpoint: "/payments/subscribe",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AccountSubscribe,
			Name:     "payment-account-subscribe",
			Type:     handler.PostRequest,
			Endpoint: "/payments/account/subscribe",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GroupSubscribe,
			Name:     "payment-group-subscribe",
			Type:     handler.PostRequest,
			Endpoint: "/payments/group/subscribe",
		},
	)

	//----------------------------------------------------------
	// Subscriptions
	//----------------------------------------------------------

	// this is same /payments/account/subscriptions, here for backwards
	// compatibilty
	m.AddHandler(
		handler.Request{
			Handler:  AccountSubscriptionRequest,
			Name:     "payment-subscriptions",
			Type:     handler.GetRequest,
			Endpoint: "/payments/subscriptions",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AccountSubscriptionRequest,
			Name:     "payment-account-subscriptions",
			Type:     handler.GetRequest,
			Endpoint: "/payments/account/subscriptions",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GroupSubscriptionRequest,
			Name:     "payment-group-subscriptions",
			Type:     handler.GetRequest,
			Endpoint: "/payments/group/subscriptions",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AccountCancelSubscriptionRequest,
			Name:     "payment-account-subscription-cancel",
			Type:     handler.PutRequest,
			Endpoint: "/payments/account/subscriptions/cancel",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GroupCancelSubscriptionRequest,
			Name:     "payment-group-subscription-cancel",
			Type:     handler.PutRequest,
			Endpoint: "/payments/group/subscriptions/cancel",
		},
	)

	//----------------------------------------------------------
	// Customers
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:  GetCustomersRequest,
			Name:     "payment-getcustomer",
			Type:     handler.GetRequest,
			Endpoint: "/payments/customers",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  DeleteCustomerRequest,
			Name:     "payment-deletecustomer",
			Type:     handler.DeleteRequest,
			Endpoint: "/payments/customers/{accountId}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  ExpireCustomerRequest,
			Name:     "payment-expirecustomer",
			Type:     handler.PostRequest,
			Endpoint: "/payments/customers/{accountId}/expire",
		},
	)

	//----------------------------------------------------------
	// Invoices
	//----------------------------------------------------------

	// this is same /payments/account/invoices/{accountId}, here for backwards
	// compatibilty
	m.AddHandler(
		handler.Request{
			Handler:  AccountInvoiceRequest,
			Name:     "payment-invoices",
			Type:     handler.GetRequest,
			Endpoint: "/payments/invoices/{accountId}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AccountInvoiceRequest,
			Name:     "payment-account-invoices",
			Type:     handler.GetRequest,
			Endpoint: "/payments/account/invoices/{accountId}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GroupInvoiceRequest,
			Name:     "payment-group-invoices",
			Type:     handler.GetRequest,
			Endpoint: "/payments/group/invoices/{groupId}",
		},
	)

	//----------------------------------------------------------
	// CreditCard
	//----------------------------------------------------------

	// this is same /payments/account/creditcard/{accountId}, here for backwards
	// compatibilty
	m.AddHandler(
		handler.Request{
			Handler:  AccountCreditCardRequest,
			Name:     "payment-creditcard",
			Type:     handler.GetRequest,
			Endpoint: "/payments/creditcard/{accountId}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AccountCreditCardRequest,
			Name:     "payment-account-creditcard",
			Type:     handler.GetRequest,
			Endpoint: "/payments/account/creditcard/{accountId}",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GroupCreditCardRequest,
			Name:     "payment-group-creditcard",
			Type:     handler.GetRequest,
			Endpoint: "/payments/group/creditcard/{groupId}",
		},
	)

	// this is same /payments/account/creditcard/update, here for backwards
	// compatibilty
	m.AddHandler(
		handler.Request{
			Handler:  AccountUpdateCreditCardRequest,
			Name:     "payment-updatecreditcard",
			Type:     handler.PostRequest,
			Endpoint: "/payments/creditcard/update",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AccountUpdateCreditCardRequest,
			Name:     "payment-account-updatecreditcard",
			Type:     handler.PostRequest,
			Endpoint: "/payments/account/creditcard/update",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GroupUpdateCreditCardRequest,
			Name:     "payment-group-updatecreditcard",
			Type:     handler.PostRequest,
			Endpoint: "/payments/group/creditcard/update",
		},
	)

	//----------------------------------------------------------
	// Paypal
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:  PaypalSuccess,
			Name:     "payment-paypalsuccess",
			Type:     handler.PostRequest,
			Endpoint: "/payments/paypal/return",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  PaypalCancel,
			Name:     "payment-paypalcancel",
			Type:     handler.PostRequest,
			Endpoint: "/payments/paypal/cancel",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  PaypalGetToken,
			Name:     "payment-paypalgettoken",
			Type:     handler.GetRequest,
			Endpoint: "/payments/paypal/token",
		},
	)
}
