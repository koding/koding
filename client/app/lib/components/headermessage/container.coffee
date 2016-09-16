_ = require 'lodash'
kd = require 'kd'
globals = require 'globals'
{ connect } = require 'react-redux'
isAdmin = require 'app/util/isAdmin'
getGroupStatus = require 'app/util/getGroupStatus'
pluralize = require 'pluralize'


HeaderMessage = require './headermessage'

subscription = require 'app/redux/modules/payment/subscription'

buttonTitles =
  admin:
    expiring: 'Enter a Credit Card'
    past_due: 'Enter Another Credit Card'

  member:
    expiring: 'Notify My Admin'
    past_due: 'Notify My Admin'

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

getGroup = (state) -> globals.currentGroup


groupStatus = (state) ->

  status = getGroupStatus getGroup state

  daysLeft = subscription.daysLeft state

  switch status
    when 'trialing'
      if daysLeft < 4 then 'expiring' else 'trialing'
    else
      status

role = -> if isAdmin() then 'admin' else 'member'

headerMessage = (state) ->

  status   = groupStatus state
  daysLeft = subscription.daysLeft state
  messages = makeHeaderMessages subscription.daysLeft state

  return messages[role()][status]


buttonTitle = (state) ->

  status = groupStatus(state)

  return buttonTitles[role()][status]


routeToCreditCard = -> kd.singletons.router.handleRoute '/Home/team-billing'
notifyAdminAbout = (status) -> -> console.log "admins notified about #{status}"

onButtonClicks =
  admin:
    expiring: routeToCreditCard
    past_due: routeToCreditCard

  member:
    expiring: notifyAdminAbout 'expiring'
    past_due: notifyAdminAbout 'past_due'


makeOnButtonClick = (state, dispatch) ->

  status = groupStatus(state)

  return onButtonClicks[role()][status]


mapStateToProps = (state) ->

  return { visible: off }  unless status = getGroup state
  return { visible: off }  unless status in ['expiring', 'past_due']

  return assign headerMessage(state),
    status: groupStatus(state)
    visible: !!headerMessage(state) and not state.creditCard
    buttonTitle: getGroup(state) and buttonTitle(state)


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

