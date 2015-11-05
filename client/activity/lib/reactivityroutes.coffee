React                     = require 'kd-react'
ActivityAppComponent      = require 'activity/components/appcomponent'
SingleChannelRoute        = require 'activity/routes/singlepublicchannel'
SinglePrivateMessageRoute = require 'activity/routes/singleprivatechannel'

module.exports = [
  path: '/Channels'
  component: ActivityAppComponent
  onLeave: ->
    threadActions.changeSelectedThread null
    messageActions.changeSelectedMessage null

  childRoutes: [
    new SingleChannelRoute
  ]
,
  path: '/Messages'
  component: ActivityAppComponent
  childRoutes: [
    new SinglePrivateMessageRoute
  ]
]

