React                     = require 'kd-react'
ActivityAppComponent      = require 'activity/components/appcomponent'
SingleChannelRoute        = require 'activity/routes/singlepublicchannel'
SinglePrivateMessageRoute = require 'activity/routes/singleprivatechannel'
NewPrivateChannelRoute    = require 'activity/routes/newprivatechannel'
NewPublicChannelRoute     = require 'activity/routes/newpublicchannel'
AllPublicChannelsRoute    = require 'activity/routes/allpublicchannels'
AllPrivateChannelsRoute   = require 'activity/routes/allprivatechannels'

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
,
  path: '/PublicChannelModals'
  component: ActivityAppComponent
  childRoutes: [
    new NewPublicChannelRoute
    new AllPublicChannelsRoute
  ]
,
  path: '/PrivateChannelModals'
  component: ActivityAppComponent
  childRoutes: [
    new NewPrivateChannelRoute
    new AllPrivateChannelsRoute
  ]
]

cleanSelectedThreads = ->
  { thread, message } = require('activity/flux').actions
  threadActions.changeSelectedThread null
  messageActions.changeSelectedMessage null

