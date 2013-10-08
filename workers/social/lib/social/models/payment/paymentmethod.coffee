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
      recurlyId   : String
      description : String

  @createPaymentMethod = secure (client, data, callback) ->
    recurlyId = createId()
    paymentMethod = new this { recurlyId, description: data.description }
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
        callback err

  associatePaymentData: secure (client, formData, callback) ->
    JSession = require '../session'

    { delegate } = client.connection

    delegate.fetchUser (err, user) =>
      return callback err  if err
      { email, username } = user
      { firstName, lastName } = delegate.profile

      delegate.hasTarget this, 'paymentMethod', (err, hasTarget) =>
        return callback err  if err
        return callback message: 'Access denied!'  unless hasTarget

        JSession.one clientId: client.sessionToken, (err, session) =>
          return callback err  if err

          ipAddress = session.clientIPAddress or '(Unknown IP address)'

          accountData = { ipAddress, username, email, firstName, lastName }

          recurly.setAccountDetailsByAccountCode @recurlyId, accountData, (err, rAccountData) =>
            return callback err  if err

            recurly.setBillingByAccountCode @recurlyId, formData, callback

  fetchAssociatedPaymentData: (callback) ->
    recurly.fetchBillingByAccountCode @recurlyId, (err, billing) =>
      return callback err  if err
      callback null, { @recurlyId, @description, billing }

  @updatePaymentMethodByAccountCode = secure (client, recurlyId, formData, callback) ->
    if recurlyId
      @one { recurlyId }, (err, paymentMethod) =>
        return callback err  if err
        if paymentMethod
        then paymentMethod.associatePaymentData client, formData, callback
        else @create client, formData, callback
    else
      @create client, formData, callback



