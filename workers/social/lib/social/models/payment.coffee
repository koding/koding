{ secure, signature, Base } = require 'bongo'
KONFIG = require 'koding-config-manager'
{ extend, defaults }  = require 'underscore'
KodingError = require '../error'

TEAM_PLANS  = require '../models/computeproviders/teamplans'

module.exports = class Payment extends Base
  @share()

  ERR_USER_NOT_CONFIRMED = 'ERR_USER_NOT_CONFIRMED'

  @set
    sharedMethods     :
      static          :
        subscribe         :
          (signature Object, Function)
        subscribeGroup    :
          (signature Object, Function)
        subscriptions     :
          (signature Object, Function)
        invoices          :
          (signature Object, Function)
        fetchGroupInvoices:
          (signature Function)
        creditCard        :
          (signature Object, Function)
        fetchGroupCreditCard:
          (signature Function)
        updateCreditCard  :
          (signature Object, Function)
        updateGroupCreditCard:
          (signature Object, Function)
        canChangePlan     :
          (signature Object, Function)
        logOrder          :
          (signature Object, Function)
        getToken          :
          (signature Object, Function)
        canUserPurchase   :
          (signature Function)
        fetchGroupPlan    :
          (signature Function)
        cancelGroupPlan:
          (signature Function)


  { get, post, deleteReq, put } = require './socialapi/requests'

  socialProxyUrl = '/api/social'


  @subscribe = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @subscribeGroup = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @fetchGroupPlan = secure (client, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @cancelGroupPlan = secure (client, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @subscriptions = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @fetchGroupInvoices = secure (client, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @invoices = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @creditCard = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @fetchGroupCreditCard$ = secure (client, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @updateCreditCard = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @updateGroupCreditCard = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @canChangePlan = secure (client, data, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @logOrder = secure (client, raw, callback) ->
    SiftScience = require './siftscience'
    SiftScience.createOrder client, raw, callback

  @canUserPurchase = secure (client, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'

  @deleteAccount = (client, callback) ->
    return callback new Error 'subscriptions are closed via this endpoint'
