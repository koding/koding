_ = require 'lodash'
kd = require 'kd'
pluralize = require 'pluralize'
globals = require 'globals'
{ connect } = require 'react-redux'

getRole = require 'app/util/getRole'
getGroup = require 'app/util/getGroup'
getGroupStatus = require 'app/util/getGroupStatus'

subscription = require 'app/redux/modules/payment/subscription'

{ Status } = require 'app/redux/modules/payment/constants'

HeaderMessage = require './headermessage'

makeHeaderMessages = (daysLeft) ->
  admin:
    expiring:
      type: 'danger'
      title: 'Your trial is about to expire.'
      description: "
        Your 1 week trial is about to expire. You have only #{pluralize 'day', daysLeft, yes}
        left. Enter your credit card to avoid any suspension.
      "
    past_due:
      type: 'danger'
      title: 'We couldn’t charge your credit card.'
      description: '
        We will try again on X date and your account will be suspended on X
        date.
      '
  member:
    expiring:
      type: 'danger'
      title: 'Your trial is about to expire.'
      description: "
        Your 1 week trial is about to expire. You have only #{pluralize 'day', daysLeft, yes}
        left. Have an admin enter a credit card to avoid any suspension.
      "
    past_due:
      type: 'danger'
      title: 'We couldn’t charge your credit card.'
      description: '
        Have an admin to enter a credit card to avoid any suspension.
      '

groupStatus = (state) ->

  status = getGroupStatus getGroup()

  daysLeft = subscription.daysLeft state

  switch status
    when Status.TRIALING
      if daysLeft < 4 then Status.EXPIRING else Status.TRIALING
    else
      status


headerMessage = (state) ->

  status   = groupStatus state
  daysLeft = subscription.daysLeft state
  messages = makeHeaderMessages daysLeft

  return messages[getRole()][status]


buttonTitles =
  admin:
    expiring: 'Enter a Credit Card'

    past_due: 'Enter Another Credit Card'

  member:
    expiring: 'Notify My Admin'
    past_due: 'Notify My Admin'


buttonTitle = (state) ->

  status = groupStatus(state)

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
  return { visible: off }  unless status in [Status.EXPIRING, Status.PAST_DUE]
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

