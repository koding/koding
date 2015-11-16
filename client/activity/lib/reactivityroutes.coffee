React                     = require 'kd-react'
ActivityAppComponent      = require 'activity/components/appcomponent'
SingleChannelRoute        = require 'activity/routes/singlepublicchannel'
SinglePrivateMessageRoute = require 'activity/routes/singleprivatechannel'

module.exports = [
  path: '/Channels'
  component: ActivityAppComponent
  childRoutes: [
    new SingleChannelRoute
  ]
  onLeave: -> cleanSelectedThreads()
,
  path: '/Messages'
  component: ActivityAppComponent
  childRoutes: [
    new SinglePrivateMessageRoute
  ]
  onLeave: -> cleanSelectedThreads()
]

cleanSelectedThreads = ->
  { thread, message } = require('activity/flux').actions
  threadActions.changeSelectedThread null
  messageActions.changeSelectedMessage null

