KONFIG      = require 'koding-config-manager'
KodingError = require '../error'

module.exports = class SiftScience

  @transaction: (client, raw, callback) ->
    { planTitle, planAmount, binNumber, lastFour, cardName, status } = raw

    return callback null  if planTitle is 'free'

    data = {
      '$type'               : '$transaction'
      '$transaction_status' : '$success'
      '$currency_code'      : 'USD'
      '$amount'             : parsePrice planAmount
      '$payment_method'     :
        '$payment_type'     : '$credit_card'
        '$payment_gateway'  : '$stripe'
        '$card_bin'         : binNumber
        '$card_last4'       : lastFour
      '$billing_address'    :
        '$name'             : cardName
    }

    @send client, 'transaction', data, callback


  @createOrder : (client, raw, callback) ->
    { planTitle, planAmount, binNumber, lastFour, cardName } = raw

    return callback null  if planTitle is 'free'

    data = {
      '$type'               : '$create_order'
      '$currency_code'      : 'USD'
      '$amount'             : parsePrice planAmount
      '$payment_methods'    : [
        '$payment_type'     : '$credit_card'
        '$payment_gateway'  : '$stripe'
        '$card_bin'         : binNumber
        '$card_last4'       : lastFour
      ]
      '$billing_address'    :
        '$name'             : cardName
      '$items'              : [
        '$item_id'          : planTitle
        '$price'            : parsePrice planAmount
      ]
    }

    @send client, 'create_order', data, callback


  @createAccount: (client, referrer, callback) ->
    data = {
      '$type'             : '$create_account'
      '$referrer_user_id' : referrer
    }

    @send client, 'create_account', data, callback


  @send = (client, event, data, callback) ->
    unless KONFIG.siftScience
      return callback new KodingError \
        'SiftScience is disabled because of missing configuration'

    siftScience = require('yield-siftscience') { api_key: KONFIG.siftScience }

    @fetchUserInfo client, (err, userInfo) ->
      return callback err   if err
      return callback new KodingError 'no user found'  unless userInfo?

      { username, email, sessionToken } = userInfo

      data['$user_id']    = username
      data['$user_email'] = email
      data['$session_id'] = sessionToken

      siftScience.event[event] data, (err, response) ->
        console.error 'Request to SiftScience failed', err, response.body  if err
        callback err, response.body


  @fetchUserInfo = (client, callback) ->
    { sessionToken, connection : { delegate } } = client

    if delegate.type isnt 'registered'
      return callback new KodingError 'guests are not allowed'

    delegate.fetchUser (err, user) ->
      return callback err  if err

      { username, email } = user
      callback null, { username, email, sessionToken }


  parsePrice = (price) ->
    price = price.slice 1  if price[0] is '$'
    return parseFloat(price) * 1000000
