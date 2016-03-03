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

	m.AddHandler(
		handler.Request{
			Handler:  InvoiceRequest,
			Name:     "payment-invoices",
			Type:     handler.GetRequest,
			Endpoint: "/payments/invoices/{accountId}",
		},
	)

	//----------------------------------------------------------
	// CreditCard
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:  CreditCardRequest,
			Name:     "payment-creditcard",
			Type:     handler.GetRequest,
			Endpoint: "/payments/creditcard/{accountId}",
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
