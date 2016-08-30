makeHttpClient = require 'app/util/makeHttpClient'
{ pickData } = makeHttpClient.helpers

exports.client = client = makeHttpClient { baseURL: '/api/social/payment' }

exports.Endpoints = Endpoints =
  SubscriptionDelete : "/subscription/delete"
  SubscriptionGet    : "/subscription/get"
  SubscriptionCreate : "/subscription/create"
  CustomerCreate     : "/customer/create"
  CustomerGet        : "/customer/get"
  CustomerUpdate     : "/customer/update"
  CustomerDelete     : "/customer/delete"
  CreditCardDelete   : "/creditcard/delete"
  InvoiceList        : "/invoice/list"
  Info               : "/info"


# fetchCustomer: fetches current group's payment customer.
exports.fetchCustomer = fetchCustomer = pickData ->
  client.get Endpoints.CustomerGet

# createCustomer: creates a customer for current group.
exports.createCustomer = createCustomer = pickData ->
  client.post Endpoints.CustomerCreate

# updateCustomer: update current group's payment customer.
exports.updateCustomer = updateCustomer = pickData (params = {}) ->
  client.post Endpoints.CustomerUpdate, params

# deleteCustomer: deletes current group's payment customer
exports.deleteCustomer = deleteCustomer = pickData (params = {}) ->
  client.delete Endpoints.CustomerDelete, params

exports.fetchSubscription = fetchSubscription = pickData ->
  client.get Endpoints.SubscriptionGet

exports.createSubscription = createSubscription = pickData ({ customer, plan }) ->
  client.post Endpoints.SubscriptionCreate, { customer, plan }

exports.deleteSubscription = deleteSubscription = pickData (params = {}) ->
  client.delete Endpoints.SubscriptionDelete, params

exports.deleteCreditCard = deleteCreditCard = pickData ->
  client.delete Endpoints.CreditCardDelete

exports.fetchInvoices = fetchInvoices = pickData ->
  client.get Endpoints.InvoiceList

