globals = require 'globals'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'
whoami = require 'app/util/whoami'

subscription = require 'app/redux/modules/payment/subscription'
customer = require 'app/redux/modules/payment/customer'
bongo = require 'app/redux/modules/bongo'

SubscriptionSection = require './subscriptionsection'


teamSize = -> globals.currentGroup?.counts?.member ? 1

subscriptionTitle = createSelector(
  subscription.pricePerSeat
  subscription.isTrial
  subscription.trialDays
  teamSize
  (pricePerSeat, isTrial, trialDays, size) ->
    if isTrial
      if trialDays is 7
      then "Koding Basic Trial (1 Week)"
      else "Koding Basic Trial (1 Month)"
    else
      noun = if 1 >= size then 'Developer' else 'Developers'
      "$#{pricePerSeat} per Developer (#{size} #{noun})"
)


freeCredit = createSelector(
  customer.coupon
  (coupon) -> if coupon then coupon.amount_off else 0
)


accountUser = createSelector(
  bongo.all('JUser')
  bongo.byId('JAccount', whoami()._id)
  (users, account) ->
    return null  if not (account and users)

    { nickname } = account.profile
    [ userId ] = Object.keys(users).filter (id) -> users[id].username is nickname

    return if userId then users[userId] else null
)


isEmailVerified = createSelector(
  accountUser
  (user) -> if user then user.status is 'confirmed' else no
)


mapStateToProps = (state) ->
  return {
    title: subscriptionTitle(state)
    pricePerSeat: subscription.pricePerSeat(state)
    teamSize: teamSize()
    endsAt: subscription.endsAt(state)
    isTrial: subscription.isTrial(state)
    freeCredit: freeCredit(state)
    # TODO(umut): activate this when we have coupon support.
    isSurveyTaken: yes # !!customer.coupon(state)
    isEmailVerified: isEmailVerified(state)
  }


module.exports = connect(mapStateToProps)(SubscriptionSection)

