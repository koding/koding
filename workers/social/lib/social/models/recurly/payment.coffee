jraphical = require 'jraphical'
recurly   = require 'koding-payment'

module.exports = class JRecurlyPayment extends jraphical.Module

  {secure,daisy} = require 'bongo'

  KodingError          = require '../../error'
  JUser                = require '../user'
  JGroup               = require '../group'
  JRecurlyPlan         = require './index'
  JRecurlySubscription = require './subscription'
  {Relationship}       = require 'jraphical'

  @share()

  @set
    sharedMethods  :
      static       : [
        'all', 'some', 'one', 'each',  # For development purposes only.
        'makePayment'
      ]
      instance     : [
        'info'
      ]
    schema           :
      planCode       : String
      planQuantity   : Number
      buyer          : String # Recurly account name
      user           : String # Recurly account name
      amount         : Number
      timestamp      : Number
      subscription   : String # Recurly UUID for subscription
      active         : Boolean

  @makePayment = secure (client, data, callback)->

    @initialize client, data, (err, group, account, plan)=>
      if err
        return callback new KodingError "Unable to access payment backend, please try again later."

      # Default quantity is 1
      data.quantity ?= 1

      # Don't allow multiple subscriptions by default
      data.multiple ?= no

      # Users can use group account to purchase items.
      if data.chargeTo is 'group'
        buyer = "group_#{group._id}"
      else
        buyer = "user_#{account._id}"

      user = "user_#{account._id}"

      if data.chargeTo is 'group'
        @canChargeGroup group, account, data, (err)=>
          return callback err  if err
          @chargeGroup group, plan, data, (err, subscription)=>
            return callback err  if err

            pay = new JRecurlyPayment
              planCode     : data.plan
              planQuantity : data.quantity
              buyer        : buyer
              user         : user
              # timestamp    : (new Date()).getTime()
              amount       : 0
              subscription : subscription.uuid
              active       : yes
            pay.save (err)->
              if err
                return callback new KodingError "Unable to save transaction to database."
              callback null, pay
      else
        @chargeUser account, plan, data, (err, subscription)=>
          return callback err  if err

          pay = new JRecurlyPayment
            planCode     : data.plan
            planQuantity : data.quantity
            buyer        : buyer
            user         : user
            # timestamp    : (new Date()).getTime()
            amount       : 0
            subscription : subscription.uuid
            active       : yes
          pay.save (err)->
            if err
              return callback new KodingError "Unable to save transaction to database."
            callback null, pay

  # Get ready for a transaction (find group, create accounts)
  @initialize = (client, data, callback)->
    account = client.connection.delegate
    slug    = client.context.group

    JGroup.one {slug}, (err, group)=>
      return callback err  if err

      @createAccount account, (err)=>
        return callback err  if err
        @createGroupAccount group, (err)=>
          return callback err  if err
          @getPlan data.plan, (err, plan)->
            return callback err  if err
            callback null, group, account, plan

  # Get plan
  @getPlan = (code, callback)->
    JRecurlyPlan.getPlanWithCode code, (err, plan)->
      if err
        return callback new KodingError "Unable to access product information. Please try again later."
      callback null, plan

  # Get price for a product
  @calculateAmount = (data, callback)->
    @getPlan data.plan, (err, plan)->
      return callback err  if err
      callback null, plan.feeMonthly * data.quantity

  # Create user account on Recurly
  @createAccount = (account, callback)->
    account.fetchUser (err, user) ->
      return callback err  if err
      data =
        username  : account.profile.nickname
        firstName : account.profile.firstName
        lastName  : account.profile.lastName
        email     : user.email
      recurly.setAccount "user_#{account._id}", data, (err, res)->
        return callback err  if err
        callback()

  # Create group account on Recurly
  @createGroupAccount = (group, callback)->
    group.fetchOwner (err, owner)->
      return callback err  if err
      owner.fetchUser (err, user)->
        return callback err  if err
        data =
          username  : group.slug
          firstName : "Group"
          lastName  : group.title
          email     : user.email
        recurly.setAccount "group_#{group._id}", data, (err, res)->
          return callback err  if err
          callback()

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
            callback new KodingError "You don't have enough balance."

  # Return quota that group gives to its users.
  @getGroupAllocation = (group, callback)->
    group.fetchBundle (err, bundle)=>
      if err or not bundle or bundle.allocation is 0
        return callback new KodingError "This group doesn't allow you to purchase."
      else
        callback null, bundle.allocation

  # Charge group account
  @chargeGroup = (group, plan, data, callback)->
    plan.subscribeGroup group,
      multiple: data.multiple
      plan    : data.plan
      quantity: data.quantity
    , (err, subscription)->
      if err
        return callback new KodingError "Unable to buy item: #{err}"
      callback null, subscription

  # Charge user account
  @chargeUser = (account, plan, data, callback)->
    return callback new KodingError "Unable charge, insufficient funds."
    # TBI

  # List group's payments
  @getGroupPayments = (group, callback)->
    @getExpenses
      buyer     : "group_#{group._id}"
      active    : yes
    , callback

  # List user's payments
  @getUserPayments = (account, callback)->
    @getExpenses
      buyer     : "user_#{account._id}"
      active    : yes
    , callback

  # List a user's payments expensed to group
  @getUserExpenses = (group, account, callback)->
    @getExpenses
      buyer     : "group_#{group._id}"
      user      : "user_#{account._id}"
      active    : yes
    , callback

  @getExpenses = (pattern, callback)->
    stack = []
    JRecurlyPayment.some pattern, {subscription: 1}, (err, items)->
      if err
        return callback new KodingError "Unable to query user balance: #{err}"
      items.forEach (item)->
        stack.push (cb)->
          recurly.getSubscription "group_#{group._id}",
            uuid: item.subscription
          , (err, subscription)->
            return cb err  if err
            cb null, subscription

      expenses = 0

      # TODO: Make sure this calculation is enough.
      # Not tested for expired/canceled subscriptions.

      async = require 'async'
      async.parallel stack, (err, results)->
        if err
          return callback new KodingError "Unable to query user balance: #{err}"
        results.forEach (sub)->
          if sub.status is 'active'
            expenses += parseInt sub.amount, 10
        callback null, expenses
