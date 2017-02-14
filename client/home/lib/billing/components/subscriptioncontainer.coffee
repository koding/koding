kd = require 'kd'
globals = require 'globals'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'
whoami = require 'app/util/whoami'
pluralize = require 'pluralize'

subscription = require 'app/redux/modules/payment/subscription'
customer = require 'app/redux/modules/payment/customer'
info = require 'app/redux/modules/payment/info'
bongo = require 'app/redux/modules/bongo'

SubscriptionSection = require './subscriptionsection'


subscriptionTitle = createSelector(
  subscription.planAmount
  info.userCount
  (amount, userCount) ->
    name = "$#{amount.toString()} Plan"

    type = if userCount is 1 then 'Solo'
    else if userCount <= 10 then 'Single Cloud'
    else 'Dev Team'

    return "#{name} (#{type})"
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

  { payment } = globals.currentGroup

  title = if payment.customer.hasCard
  then subscriptionTitle(state)
  else 'Cancelled Subscription'

  return {
    title: title
    pricePerSeat: subscription.pricePerSeat(state)
    teamSize: info.userCount(state)
    endsAt: info.endsAt(state)
    daysLeft: info.daysLeft(state)
    isTrial: subscription.isTrial(state)
    freeCredit: customer.freeCredit(state)
    # TODO(umut): activate this when we have coupon support.
    isSurveyTaken: yes # !!customer.coupon(state)
    isEmailVerified: isEmailVerified(state)
    hasCreditCard: payment.customer.hasCard
  }


mapDispatchToProps = (dispatch) ->
  return {
    onClickPricingDetails: -> window.open 'https://www.koding.com/pricing', '_blank'
    onClickViewMembers: -> kd.singletons.router.handleRoute '/Home/my-team#teammates'
  }


module.exports = connect(mapStateToProps, mapDispatchToProps)(SubscriptionSection)
