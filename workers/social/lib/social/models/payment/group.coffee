recurly     = require 'koding-payment'
JPayment    = require './index'
{ extend }  = require 'underscore'

module.exports = class JPaymentGroup extends JPayment

  # { groupCodeOf } = this

  # @setPaymentInfo = (client, group, data, callback)->
  #   console.trace()
  #   group.fetchOwner (err, owner) ->
  #     return callback err  if err
  #     owner.fetchUser (err, ownerUser) ->
  #       return callback err  if err

  #       {email, username} = ownerUser

  #       {firstName, lastName} = owner.profile

  #       paymentMethodId = groupCodeOf group

  #       extend data, {
  #         paymentMethodId
  #         email
  #         username
  #         firstName
  #         lastName
  #       }

  #       recurly.setAccountDetailsByPaymentMethodId paymentMethodId, data, (err, res) ->
  #         return callback err  if err
  #         recurly.setPaymentMethodById paymentMethodId, data, callback
#
#  @fetchAccountDetails = (group, callback) ->
#    recurly.fetchAccountDetailsByPaymentMethodId (groupCodeOf group), callback
#
#  @fetchPaymentMethod = (group, callback) ->
#    recurly.fetchPaymentMethodById (groupCodeOf group), callback
#
#  @fetchTransactions = (group, callback) ->
#    recurly.fetchTransactions (groupCodeOf group), callback

  @addPlan = (group, data, callback) ->
    data.feeAmount = data.price
    data.feeInitial = 0
    data.planCode = "groupplan_#{group.getId()}_#{data.name}_0"
    # 9999 is a hack, since Recurly sucks at non-recurring payments
    data.feeInterval = if data.type is 'recurring' then 1 else 9999

    recurly.createPlan data, callback

  @deletePlan = (group, data, callback) ->
    if data.planCode.indexOf("groupplan_#{group.getId()}_") > -1
      recurly.deletePlan data, callback

  @fetchAccount = (group, callback) ->
    group.fetchOwner (err, owner) ->
      return callback err  if err
      owner.fetchUser (err, user) ->
        return callback err  if err
        callback null,
          email     : user.email
          username  : group.slug
          firstName : 'Group'
          lastName  : group.title

  @getBalance = (group, callback) ->
    @getBalance_ (groupCodeOf group), callback


