recurly  = require 'koding-payment'
JRecurly = require './index'

module.exports = class JRecurlyGroup extends JRecurly

  @setAccount = (client, group, data, callback)->
    console.log { client, group, data }
    JSession = require '../session'
    JSession.one {clientId: client.sessionToken}, (err, session) =>
    JRecurlyPlan.fetchGroupAccount group, (err, groupAccount) =>
      return callback err  if err
      {email, username, firstName, lastName} = groupAccount
      
      accountCode = "group_#{group.getId()}"
      extend data, {accountCode, email, username, firstName, lastName}

      recurly.setAccount accountCode, data, (err, res)->
        return callback err  if err
        recurly.setBilling accountCode, data, callback

  @getAccount = (group, callback) ->
    recurly.getAccount "group_#{group.getId()}", callback

  @getBilling = (group, callback) ->
    recurlyId = "group_#{group.getId()}"
    JRecurlyBillingMethod = require '../recurly/billingmethod'

    recurly.getBilling recurlyId, (err, billing) ->
      return callback err  if err?

      JRecurlyBillingMethod.one { recurlyId }, (err, mixin) ->
        return callback err  if err?

        billing = _.extend billing, mixin  if mixin?

        callback null, billing

  @getTransactions = (group, callback)->
    recurly.getTransactions "group_#{group.getId()}", callback

  @addPlan = (group, data, callback)->
    data.feeMonthly = data.price
    data.feeInitial = 0
    data.code       = "groupplan_#{group.getId()}_#{data.name}_0"
    # 9999 is a hack, since Recurly sucks at non-recurring payments
    data.feeInterval = if data.type is 'recurring' then 1 else 9999

    recurly.createPlan data, callback

  @deletePlan = (group, data, callback)->
    if data.code.indexOf("groupplan_#{group.getId()}_") > -1
      recurly.deletePlan data, callback

  @fetchAccount = (group, callback)->
    group.fetchOwner (err, owner)->
      return callback err  if err
      owner.fetchUser (err, user)->
        return callback err  if err
        callback null,
          email     : user.email
          username  : group.slug
          firstName : "Group"
          lastName  : group.title

  @getBalance = (group, callback)->
    @getBalance_ "group_#{group.getId()}", callback
