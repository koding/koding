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
    name = "$#{amount.dollars} Plan"
    type = if userCount is 1 then 'Solo' else userCount
    pluralized = pluralize 'Developer', userCount

    return "#{name} (#{type} #{pluralized})"
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

  title = if globals.hasCreditCard
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
    hasCreditCard: globals.hasCreditCard
  }


mapDispatchToProps = (dispatch) ->
  return {
    onClickPricingDetails: -> window.open 'https://www.koding.com/pricing', '_blank'
    onClickViewMembers: -> kd.singletons.router.handleRoute '/Home/my-team#teammates'
  }


module.exports = connect(mapStateToProps, mapDispatchToProps)(SubscriptionSection)
