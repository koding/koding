immutable = require 'app/util/immutable'
dateDiffInDays = require 'app/util/dateDiffInDays'
{ createSelector } = require 'reselect'

reduxHelper = require 'app/redux/helper'
schemas = require './schemas'

withNamespace = reduxHelper.makeNamespace 'koding', 'payment', 'info'

LOAD = reduxHelper.expandActionType withNamespace 'LOAD'

reducer = (state = null, action = {}) ->

  { normalize } = reduxHelper

  switch action.type
    when LOAD.SUCCESS
      normalized = normalize action.result, schemas.info
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


module.exports = {
  namespace: withNamespace()
  reducer

  due, nextBillingDate, daysLeft, userCount, endsAt

  load
  LOAD
}
