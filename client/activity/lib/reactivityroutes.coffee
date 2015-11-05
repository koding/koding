React                     = require 'kd-react'
ActivityAppComponent      = require 'activity/components/appcomponent'
SingleChannelRoute        = require 'activity/routes/singlepublicchannel'
SinglePrivateMessageRoute = require 'activity/routes/singleprivatechannel'
ChannelThreadPane        = require 'activity/components/channelthreadpane'
PrivateMessageThreadPane = require 'activity/components/privatemessagethreadpane'
CreatePublicChannelModal = require 'activity/components/createpublicchannelmodal'
CreatePrivateChannelModal = require 'activity/components/createprivatechannelmodal'
BrowsePublicChannelsModal = require 'activity/components/browsepublicchannelsmodal'
BrowsePrivateChannelsModal = require 'activity/components/browseprivatechannelsmodal'

module.exports = [
  path: '/Channels'

  component: ActivityAppComponent

  onLeave: ->
    threadActions.changeSelectedThread null
    messageActions.changeSelectedMessage null

  indexRoute:
    components:
      content: ChannelThreadPane
      modal: BrowsePublicChannelsModal

  childRoutes: [
    new SingleChannelRoute
  ]
,
  path: '/Messages'
  component: ActivityAppComponent
  indexRoute:
    components:
      content: PrivateMessageThreadPane
      modal: BrowsePrivateChannelsModal
  childRoutes: [
    new SinglePrivateMessageRoute
    path: '/NewMessage'
    components:
      content: PrivateMessageThreadPane
      modal: CreatePrivateChannelModal
  ]
]

