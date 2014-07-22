{Module, Relationship} = require 'jraphical'

module.exports = class JPaymentMethod extends Module

  {secure, dash, signature} = require 'bongo'
  {extend} = require 'underscore'
  { v4: createId } = require 'node-uuid'

  recurly = require 'koding-payment'

  @share()

  @set
    sharedEvents    :
      static        : []
      instance      : []
    sharedMethods:
      static:
        create:
          (signature Object, Function)
    schema:
      paymentMethodId:  String
      description:      String

  @decoratePaymentMethods = (paymentMethods, callback) ->
    paymentData = []
    badMethods = []

    queue = paymentMethods.map (paymentMethod, i) -> ->
      if paymentMethod
        paymentMethod.fetchAssociatedPaymentData (err, associatedData) ->
          if err?[0].short is 'not_found'
            paymentData[i] = null
            badMethods.push paymentMethod

          else if err then return callback err, []

          paymentData[i] = associatedData

          queue.fin()
      else queue.fin()

    dash queue, ->
      cleanupQueue = badMethods.map (badMethod) -> ->
        badMethod.remove (err) -> cleanupQueue.fin err

      dash cleanupQueue, ->
        callback null, paymentData.filter Boolean

  @removePaymentMethod = secure (client, paymentMethodId, callback) ->

    { delegate } = client.connection

    @one { paymentMethodId }, (err, paymentMethod) ->
      return callback err  if err

      delegate.hasTarget paymentMethod, 'payment method', (err, hasTarget) ->
        return callback err  if err

        if hasTarget
          recurly.deleteAccount paymentMethodId, (err) ->
            return callback err  if err

            paymentMethod.remove callback


  @createPaymentMethod = secure (client, data, callback) ->
    paymentMethodId = createId()
    paymentMethod = new this { paymentMethodId, description: data.description }
    paymentMethod.save (err) ->
      return callback err  if err

      paymentMethod.associatePaymentData client, data, (err) ->
        if err
          paymentMethod.remove()
          return callback err
        callback null, paymentMethod

  @create = secure (client, formData, callback) ->
    {delegate} = client.connection

    @createPaymentMethod client, formData, (err, paymentMethod) ->
      return callback err  if err

      delegate.addPaymentMethod paymentMethod, (err) ->
        return callback err  if err

        paymentMethod.fetchAssociatedPaymentData callback

  requirePaymentFields: (fields) ->
    for field in [
      'cardZipcode'
      'cardFirstName'
      'cardLastName'
      'cardCV'
      'cardNumber'
      'cardMonth'
      'cardYear'
    ]
      unless fields[field]?
        return no
    return yes

  associatePaymentData: secure (client, formData, callback) ->
    JSession = require '../session'

    unless @requirePaymentFields formData
      return callback message: 'Missed a required value!'

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

          ipAddress = session.clientIP or '(Unknown IP address)'

          firstName ?= formData.cardFirstName
          lastName ?= formData.cardLastName

          formData.ipAddress = ipAddress

          accountData = { ipAddress, username, email, firstName, lastName }

          recurly.setAccountDetailsByPaymentMethodId @paymentMethodId, accountData, (err, rAccountData) =>
            return callback err  if err

            recurly.setPaymentMethodById @paymentMethodId, formData, (err) =>
              return callback err  if err

              @fetchAssociatedPaymentData callback

  fetchAssociatedPaymentData: (callback) ->
    recurly.fetchPaymentMethodById @paymentMethodId, (err, billing) =>
      return callback err  if err
      callback null, { @paymentMethodId, @description, billing }

  @updatePaymentMethodById = secure (client, paymentMethodId, formData, callback) ->
    if paymentMethodId
      @one { paymentMethodId }, (err, paymentMethod) =>
        return callback err  if err
        if paymentMethod
        then paymentMethod.associatePaymentData client, formData, callback
        else @create client, formData, callback
    else
      @create client, formData, callback



