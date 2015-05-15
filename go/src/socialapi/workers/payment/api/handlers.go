package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	//----------------------------------------------------------
	// Subscriptions
	//----------------------------------------------------------

	m.AddHandler(
		handler.Request{
			Handler:  Subscribe,
			Name:     "payment-subsrcibe",
			Type:     handler.PostRequest,
			Endpoint: "/payments/subscribe",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  SubscriptionRequest,
			Name:     "payment-subscriptions",
			Type:     handler.GetRequest,
			Endpoint: "/payments/subscriptions",
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

	m.AddHandler(
		handler.Request{
			Handler:  UpdateCreditCardRequest,
			Name:     "payment-updatecreditcard",
			Type:     handler.PostRequest,
			Endpoint: "/payments/creditcard/update",
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
