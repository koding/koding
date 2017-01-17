_ = require 'lodash'
kd = require 'kd'
pluralize = require 'pluralize'
globals = require 'globals'
{ connect } = require 'react-redux'

getRole = require 'app/util/getRole'
getGroup = require 'app/util/getGroup'
getGroupStatus = require 'app/util/getGroupStatus'
isGroupDisabled = require 'app/util/isGroupDisabled'

subscription = require 'app/redux/modules/payment/subscription'

{ Status } = require 'app/redux/modules/payment/constants'

HeaderMessage = require './headermessage'

makeHeaderMessages = (trialDays, daysLeft) ->

  admin = {}
  admin[Status.EXPIRING] =
    type: 'danger'
    title: 'Your trial is about to expire.'
    description: "
      Your 1 #{if trialDays is 7 then 'week' else 'month'} trial is about to
      expire. You have only #{pluralize 'day', daysLeft, yes} left. Enter your
      credit card to avoid any suspension.
    "

  admin[Status.PAST_DUE] = admin[Status.CANCELED] =
    type: 'danger'
    title: 'We couldn’t charge your credit card.'
    description: '
      Your account is suspended because we were unable to charge your card on
      file. Please enter a new card to continue using Koding.
    '

  member = {}
  member[Status.EXPIRING] =
    type: 'danger'
    title: 'Your trial is about to expire.'
    description: "
      Your 1 #{if trialDays is 7 then 'week' else 'month'} trial is about to
      expire. You have only #{pluralize 'day', daysLeft, yes} left. Have an
      admin enter a credit card to avoid any suspension.
    "

  return { admin, member }


groupStatus = (state) ->

  status = getGroupStatus getGroup()

  daysLeft = subscription.daysLeft state

  if Status.TRIALING and daysLeft < 4
  then Status.EXPIRING
  else status


headerMessage = (state) ->

  status   = groupStatus state
  daysLeft = subscription.daysLeft state
  trialDays = subscription.trialDays state
  messages = makeHeaderMessages trialDays, daysLeft

  return messages[getRole()][status]


makeButtonTitles = (creditCard) ->

  admin = {}

  prefix = if creditCard then 'Another ' else 'a '

  admin[Status.EXPIRING] = 'Enter a Credit Card'
  admin[Status.PAST_DUE] = "Enter #{prefix}Credit Card"
  admin[Status.CANCELED] = "Enter #{prefix}Credit Card"

  member = {}
  member[Status.EXPIRING] = 'Notify My Admin'
  member[Status.PAST_DUE] = 'Notify My Admin'

  return { admin, member }


buttonTitle = (state) ->

  status = groupStatus(state)
  buttonTitles = makeButtonTitles state.creditCard

  return buttonTitles[getRole()][status]


routeToCreditCard = -> kd.singletons.router.handleRoute '/Home/team-billing'

notifyAdminAbout = (status) -> console.log "admins notified about #{status}"

onButtonClicks =
  admin:
    expiring: routeToCreditCard
    past_due: routeToCreditCard

  member:
    expiring: -> notifyAdminAbout Status.EXPIRING
    past_due: -> notifyAdminAbout Status.PAST_DUE


makeOnButtonClick = (state, dispatch) ->

  status = groupStatus(state)

  return onButtonClicks[getRole()][status]


mapStateToProps = (state) ->

  return { visible: off }  unless status = groupStatus state
  return { visible: off }  unless isGroupDisabled getGroup()
  return { visible: off }  unless state.subscription

  messageProps = headerMessage(state)

  return assign messageProps,
    status: groupStatus state
    visible: !!messageProps and not state.creditCard
    buttonTitle: buttonTitle(state)


mergeProps = (stateProps, dispatchProps, ownProps) ->

  extraProps = if stateProps.status
  then { onButtonClick: makeOnButtonClick stateProps, dispatchProps.dispatch }
  else { onButtonClick: -> }

  return assign stateProps, dispatchProps, ownProps, extraProps


module.exports = connect(
  mapStateToProps
  null
  mergeProps
)(HeaderMessage)


assign = (args...) -> _.assign {}, args...
