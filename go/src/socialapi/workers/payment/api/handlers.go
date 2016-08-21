package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  DeleteSubscription,
			Name:     "payment-delete-subscription",
			Type:     handler.DeleteRequest,
			Endpoint: "/payment/subscription/delete",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  UpdateSubscription,
			Name:     "payment-update-subscription",
			Type:     handler.PostRequest,
			Endpoint: "/payment/subscription/update",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetSubscription,
			Name:     "payment-get-subscription",
			Type:     handler.GetRequest,
			Endpoint: "/payment/subscription/get",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  CreateSubscription,
			Name:     "payment-create-subscription",
			Type:     handler.PostRequest,
			Endpoint: "/payment/subscription/create",
		},
	)

	// Customers

	m.AddHandler(
		handler.Request{
			Handler:  DeleteCustomer,
			Name:     "payment-delete-customer",
			Type:     handler.DeleteRequest,
			Endpoint: "/payment/customer/delete",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  UpdateCustomer,
			Name:     "payment-update-customer",
			Type:     handler.PostRequest,
			Endpoint: "/payment/customer/update",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetCustomer,
			Name:     "payment-get-customer",
			Type:     handler.GetRequest,
			Endpoint: "/payment/customer/get",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  CreateCustomer,
			Name:     "payment-create-customer",
			Type:     handler.PostRequest,
			Endpoint: "/payment/customer/create",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  DeleteCreditCard,
			Name:     "payment-delete-creditcard",
			Type:     handler.DeleteRequest,
			Endpoint: "/payment/creditcard/delete",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Webhook,
			Name:     "payment-webhoook",
			Type:     handler.PostRequest,
			Endpoint: "/payment/webhook",
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  ListInvoice,
			Name:     "payment-list-invoices",
			Type:     handler.GetRequest,
			Endpoint: "/payment/invoice/list",
		},
	)
}
