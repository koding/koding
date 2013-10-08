{Module, Relationship} = require 'jraphical'

module.exports = class JPaymentPaymentMethod extends Module

  {secure} = require 'bongo'
  {extend} = require 'underscore'
  createId = require 'hat'

  recurly = require 'koding-payment'

  @share()

  @set
    sharedMethods :
      static      : [
        'create'
      ]
      instance    : [
        'associatePaymentData'
      ]
    schema        :
      accountCode   : String
      description : String

  @removePaymentMethod = secure (client, accountCode, callback) ->

    { delegate } = client.connection

    @one { accountCode }, (err, paymentMethod) ->
      return callback err  if err

      delegate.hasTarget paymentMethod, 'payment method', (err, hasTarget) ->
        return callback err  if err

        if hasTarget
          recurly.deleteAccount accountCode, (err) ->
            return callback err  if err

            paymentMethod.remove callback


  @createPaymentMethod = secure (client, data, callback) ->
    accountCode = createId()
    paymentMethod = new this { accountCode, description: data.description }
    paymentMethod.save (err) ->
      return callback err  if err

      paymentMethod.associatePaymentData client, data, (err) ->
        return callback err  if err
        callback null, paymentMethod

  @create = secure (client, formData, callback) ->
    {delegate} = client.connection

    @createPaymentMethod client, formData, (err, paymentMethod) ->
      return callback err  if err

      delegate.addPaymentMethod paymentMethod, (err)->
        return callback err  if err
        callback null, paymentMethod

  associatePaymentData: secure (client, formData, callback) ->
    JSession = require '../session'

    { delegate } = client.connection

    delegate.fetchUser (err, user) =>
      return callback err  if err
      { email, username } = user
      { firstName, lastName } = delegate.profile

      delegate.hasTarget this, 'payment method', (err, hasTarget) =>
        return callback err  if err
        return callback message: 'Access denied!'  unless hasTarget

        JSession.one clientId: client.sessionToken, (err, session) =>
          return callback err  if err

          ipAddress = session.clientIPAddress or '(Unknown IP address)'

          accountData = { ipAddress, username, email, firstName, lastName }

          recurly.setAccountDetailsByAccountCode @accountCode, accountData, (err, rAccountData) =>
            return callback err  if err

            recurly.setBillingByAccountCode @accountCode, formData, callback

  fetchAssociatedPaymentData: (callback) ->
    recurly.fetchBillingByAccountCode @accountCode, (err, billing) =>
      return callback err  if err
      callback null, { @accountCode, @description, billing }

  @updatePaymentMethodByAccountCode = secure (client, accountCode, formData, callback) ->
    if accountCode
      @one { accountCode }, (err, paymentMethod) =>
        return callback err  if err
        if paymentMethod
        then paymentMethod.associatePaymentData client, formData, callback
        else @create client, formData, callback
    else
      @create client, formData, callback



