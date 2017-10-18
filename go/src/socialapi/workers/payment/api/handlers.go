package api

import (
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"
)

const (
	EndpointSubscriptionCancel   = "/payment/subscription/delete"
	EndpointSubscriptionGet      = "/payment/subscription/get"
	EndpointSubscriptionCreate   = "/payment/subscription/create"
	EndpointCustomerCreate       = "/payment/customer/create"
	EndpointCustomerGet          = "/payment/customer/get"
	EndpointCustomerUpdate       = "/payment/customer/update"
	EndpointCustomerDelete       = "/payment/customer/delete"
	EndpointCreditCardDelete     = "/payment/creditcard/delete"
	EndpointCreditCardHas        = "/payment/creditcard/has"
	EndpointCreditCardAuth       = "/payment/creditcard/auth"
	EndpointWebhook              = "/payment/webhook"
	EndpointInvoiceList          = "/payment/invoice/list"
	EndpointInfo                 = "/payment/info"
	EndpointCustomCustomerCreate = "/payment/custom-customer/create"
)

// AddHandlers injects handlers for payment system
func AddHandlers(m *mux.Mux) {
	m.AddHandler(
		handler.Request{
			Handler:  CancelSubscription,
			Name:     "payment-delete-subscription",
			Type:     handler.DeleteRequest,
			Endpoint: EndpointSubscriptionCancel,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetSubscription,
			Name:     "payment-get-subscription",
			Type:     handler.GetRequest,
			Endpoint: EndpointSubscriptionGet,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  CreateSubscription,
			Name:     "payment-create-subscription",
			Type:     handler.PostRequest,
			Endpoint: EndpointSubscriptionCreate,
		},
	)

	// Customers

	m.AddHandler(
		handler.Request{
			Handler:  DeleteCustomer,
			Name:     "payment-delete-customer",
			Type:     handler.DeleteRequest,
			Endpoint: EndpointCustomerDelete,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  UpdateCustomer,
			Name:     "payment-update-customer",
			Type:     handler.PostRequest,
			Endpoint: EndpointCustomerUpdate,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  GetCustomer,
			Name:     "payment-get-customer",
			Type:     handler.GetRequest,
			Endpoint: EndpointCustomerGet,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  CreateCustomer,
			Name:     "payment-create-customer",
			Type:     handler.PostRequest,
			Endpoint: EndpointCustomerCreate,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  CreateCustomCustomer,
			Name:     "payment-create-custom-customer",
			Type:     handler.PostRequest,
			Endpoint: EndpointCustomCustomerCreate,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  DeleteCreditCard,
			Name:     "payment-delete-creditcard",
			Type:     handler.DeleteRequest,
			Endpoint: EndpointCreditCardDelete,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  HasCreditCard,
			Name:     "payment-has-creditcard",
			Type:     handler.GetRequest,
			Endpoint: EndpointCreditCardHas,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  AuthCreditCard,
			Name:     "payment-auth-creditcard",
			Type:     handler.PostRequest,
			Endpoint: EndpointCreditCardAuth,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Webhook,
			Name:     "payment-webhoook",
			Type:     handler.PostRequest,
			Endpoint: EndpointWebhook,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  ListInvoice,
			Name:     "payment-list-invoices",
			Type:     handler.GetRequest,
			Endpoint: EndpointInvoiceList,
		},
	)

	m.AddHandler(
		handler.Request{
			Handler:  Info,
			Name:     "payment-info",
			Type:     handler.GetRequest,
			Endpoint: EndpointInfo,
		},
	)
}
