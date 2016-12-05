_ = require 'lodash'
makeHttpClient = require 'app/util/makeHttpClient'
{ pickData } = makeHttpClient.helpers

{ Status } = require 'app/redux/modules/payment/constants'

exports.client = client = makeHttpClient { baseURL: '/api/social/payment' }

exports.Endpoints = Endpoints =
  SubscriptionDelete : '/subscription/delete'
  SubscriptionGet    : '/subscription/get'
  SubscriptionCreate : '/subscription/create'
  CustomerCreate     : '/customer/create'
  CustomerGet        : '/customer/get'
  CustomerUpdate     : '/customer/update'
  CustomerDelete     : '/customer/delete'
  CreditCardDelete   : '/creditcard/delete'
  CreditCardHas      : '/creditcard/has'
  CreditCardAuth     : '/creditcard/auth'
  InvoiceList        : '/invoice/list'
  Info               : '/info'


# fetchCustomer: fetches current group's payment customer.
exports.fetchCustomer = fetchCustomer = pickData ->
  client.get Endpoints.CustomerGet

# createCustomer: creates a customer for current group.
exports.createCustomer = createCustomer = pickData (params = {}) ->
  client.post Endpoints.CustomerCreate, params

# updateCustomer: update current group's payment customer.
exports.updateCustomer = updateCustomer = pickData (params = {}) ->
  client.post Endpoints.CustomerUpdate, params

# deleteCustomer: deletes current group's payment customer
exports.deleteCustomer = deleteCustomer = pickData (params = {}) ->
  client.delete Endpoints.CustomerDelete, params

exports.fetchSubscription = fetchSubscription = pickData ->
  client.get Endpoints.SubscriptionGet

exports.createSubscription = createSubscription = pickData (params = {}) ->

  params.trialEnd ?= getTimestamp(new Date)

  client.post Endpoints.SubscriptionCreate, params

exports.deleteSubscription = deleteSubscription = pickData (params = {}) ->
  client.delete Endpoints.SubscriptionDelete, params

exports.deleteCreditCard = deleteCreditCard = pickData ->
  client.delete Endpoints.CreditCardDelete

exports.fetchInvoices = fetchInvoices = pickData ->
  client.get Endpoints.InvoiceList

exports.fetchInfo = fetchInfo = ->
  client.get(Endpoints.Info).then ({ data: info }) ->
    # if status is trialing, use `trialInfo`
    if info.subscription.status is Status.TRIALING
      info = _.assign(_.omit(info, 'trialInfo'), info.trialInfo)
    return info


exports.hasCreditCard = -> client.get Endpoints.CreditCardHas

getTimestamp = (date) ->

  thirtyDaysInMs = (30 * 24 * 60 * 60 * 1000)

  Math.round (date.getTime() + thirtyDaysInMs) / 1000

