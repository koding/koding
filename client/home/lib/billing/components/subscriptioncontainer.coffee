kd = require 'kd'
globals = require 'globals'
{ connect } = require 'react-redux'
{ createSelector } = require 'reselect'
whoami = require 'app/util/whoami'
hasCreditCard = require 'app/util/hasCreditCard'
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


mapStateToProps = (state) ->

  { currentGroup, userStatus } = globals
  { payment } = currentGroup

  title = if hasCreditCard(payment)
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
    isEmailVerified: userStatus is 'confirmed'
    hasCreditCard: hasCreditCard(payment)
  }


mapDispatchToProps = (dispatch) ->
  return {
    onClickPricingDetails: -> window.open 'https://www.koding.com/pricing', '_blank'
    onClickViewMembers: -> kd.singletons.router.handleRoute '/Home/my-team#teammates'
  }


module.exports = connect(mapStateToProps, mapDispatchToProps)(SubscriptionSection)
