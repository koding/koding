jraphical = require 'jraphical'
recurly   = require 'koding-payment'

module.exports = class JPaymentPayment extends jraphical.Module

  {secure, daisy, signature}      = require 'bongo'

  JUser                = require '../user'
  JGroup               = require '../group'
  JPaymentPlan         = require './index'
  JPaymentSubscription = require './subscription'
  {Relationship}       = require 'jraphical'

  @share()

  @set
    sharedEvents      :
      static          : []
      instance        : []
    sharedMethods     :
      static          :
        makePayment   :
          (signature Object, Function)
    schema            :
      planCode        : String
      planQuantity    : Number
      buyer           : String # Recurly account name
      user            : String # Recurly account name
      amount          : Number
      timestamp       : Number
      subscription    : String # Recurly UUID for subscription
      active          : Boolean

  @makePayment = secure (client, data, callback)->
    @initialize client, data, (err, group, account, plan)=>
      if err then return callback { message: 'Unable to access payment backend, please try again later.' }

      data.quantity ?= 1  # Default quantity is 1
      data.multiple ?= no # Don't allow multiple subscriptions by default

      user  = buyer = "user_#{account.getId()}"
      buyer = "group_#{group.getId()}"  if data.chargeTo is 'group'

      charge = (subscription)->
        pay = new JPaymentPayment {
          buyer
          user
          subscription
          planCode     : data.plan
          planQuantity : data.quantity
          amount       : 0
          active       : yes
        }
        pay.save (err)->
          if err then return callback { message: 'Unable to save transaction to database.' }
          callback null, pay

      if data.chargeTo is 'group'
        @canChargeGroup group, account, data, (err)=>
          return callback err  if err
          @chargeGroup group, plan, data, (err, subscription)=>
            return callback err  if err
            charge subscription.uuid
      else
        @chargeUser account, plan, data, (err, subscription)=>
          return callback err  if err
          charge subscription.uuid

  # Get ready for a transaction (find group, create accounts)
  @initialize = (client, data, callback) ->
    account = client.connection.delegate
    slug    = client.context.group

    JGroup.one {slug}, (err, group) =>
      return callback err  if err
      @createAccount account, (err) =>
        return callback err  if err
        @createGroupAccount group, (err) =>
          return callback err  if err
          @fetchPlan data.plan, (err, plan) ->
            return callback err  if err
            callback null, group, account, plan

  # Get plan
  @fetchPlan = (planCode, callback) ->
    JPaymentPlan.fetchPlanByCode planCode, (err, plan) ->
      if err then return callback { message: 'Unable to access product information. Please try again later.' }
      callback null, plan

  # Get price for a product
  @calculateAmount = (data, callback) ->
    @fetchPlan data.plan, (err, plan) ->
      return callback err  if err
      callback null, plan.feeAmount * data.quantity

  # Create user account on Recurly
  @createAccount = (account, callback) ->
    account.fetchUser (err, user) ->
      return callback err  if err
      {nickname, firstName, lastName} = account.profile
      data = {email: user.email, nickname, firstName, lastName}
      recurly.setAccountDetailsByPaymentMethodId "user_#{account.getId()}", data, callback

  # Create group account on Recurly
  @createGroupAccount = (group, callback) ->
    group.fetchOwner (err, owner) ->
      return callback err  if err
      owner.fetchUser (err, user) ->
        return callback err  if err
        data =
          username  : group.slug
          firstName : 'Group'
          lastName  : group.title
          email     : user.email
        recurly.setAccountDetailsByPaymentMethodId "group_#{group.getId()}", data, callback

  # Tell if user can buy an item and expense it to group.
  @canChargeGroup = (group, account, data, callback)->
    @calculateAmount data, (err, amount)=>
      return callback err  if err
      @getGroupAllocation group, (err, allocation)=>
        return callback err  if err
        @getUserExpenses group, account, (err, expenses)=>
          return callback err  if err
          if allocation >= expenses + amount
            callback()
          else
            callback { message: "Insufficient balance." }

  # Return quota that group gives to its users.
  @getGroupAllocation = (group, callback)->
    group.fetchBundle (err, bundle)=>
      if err or not bundle or bundle.allocation is 0
        return callback { message: "This group doesn't allow you to purchase." }
      else
        callback null, bundle.allocation

  # Charge group account
  @chargeGroup = (group, p, data, callback)->
    {multiple, plan, quantity} = data
    p.subscribeGroup group, {multiple, plan, quantity}, (err, subscription)->
      if err then return callback { message: "Unable to buy item: #{err}" }
      callback null, subscription

  # Charge user account
  @chargeUser = (account, plan, data, callback)->
    return callback { message: 'Not implemented!' }
    # TBI

  # List group's payments
  @getGroupPayments = (group, callback)->
    @getExpenses
      buyer     : "group_#{group.getId()}"
      active    : yes
    , callback

  # List user's payments
  @getUserPayments = (account, callback)->
    @getExpenses
      buyer     : "user_#{account.getId()}"
      active    : yes
    , callback

  # List a user's payments expensed to group
  @getUserExpenses = (group, account, callback)->
    @getExpenses
      buyer     : "group_#{group.getId()}"
      user      : "user_#{account.getId()}"
      active    : yes
    , callback

  # TODO: Make sure this calculation is enough.
  #       Not tested for expired/canceled subscriptions.
  @getExpenses = (pattern, callback) ->
    error = (err)-> { message: "Unable to query user balance: #{err}" }

    JPaymentPayment.some pattern, {subscription: 1}, (err, items) ->
      return callback error err  if err
      recurly.fetchSubscriptions "group_#{group.getId()}", (err, subs) ->
        return callback error err  if err
        uuids = (item.subscription for item in items)
        expenses = 0
        for sub in subs when sub.uuid in uuids
          expenses += parseInt sub.amount, 10

        callback null, expenses
