_ = require 'lodash'
immutable = require 'app/util/immutable'
dateDiffInDays = require 'app/util/dateDiffInDays'
{ createSelector } = require 'reselect'

{ makeNamespace, expandActionType,
  normalize, defineSchema } = require 'app/redux/helper'

{ info: schema } = require './schemas'

withNamespace = makeNamespace 'koding', 'payment', 'info'

LOAD = expandActionType withNamespace 'LOAD'

reducer = (state = null, action = {}) ->

  switch action.type
    when LOAD.SUCCESS
      normalized = normalize action.result, schema
      return immutable normalized.first 'info'

    else
      return state


load = ->
  return {
    types: [LOAD.BEGIN, LOAD.SUCCESS, LOAD.FAIL]
    payment: (service) -> service.fetchInfo()
  }


due = (state) -> state.paymentInfo?.due

nextBillingDate = (state) -> state.paymentInfo?.nextBillingDate

userCount = (state) -> state.paymentInfo?.user.total

daysLeft = createSelector(
  nextBillingDate
  (billingDate) -> dateDiffInDays(new Date(billingDate), new Date)
)

endsAt = createSelector(
  nextBillingDate
  (billingDate) -> (new Date billingDate).getTime()
)


module.exports = _.assign reducer, {
  namespace: withNamespace()
  schema
  reducer

  due, nextBillingDate, daysLeft, userCount, endsAt

  load
  LOAD
}


