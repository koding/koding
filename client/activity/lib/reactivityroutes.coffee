kd                       = require 'kd'
React                    = require 'kd-react'
PublicChatPane           = require 'activity/components/publicchatpane'
PublicFeedPane           = require 'activity/components/publicfeedpane'
ChannelThreadPane        = require 'activity/components/channelthreadpane'
PostPane                 = require 'activity/components/postpane'
PrivateMessageThreadPane = require 'activity/components/privatemessagethreadpane'
CreatePublicChannelModal = require 'activity/components/createpublicchannelmodal'
CreatePrivateChannelModal = require 'activity/components/createprivatechannelmodal'
BrowsePublicChannelsModal = require 'activity/components/browsepublicchannelsmodal'
BrowsePrivateChannelsModal = require 'activity/components/browseprivatechannelsmodal'

ActivityAppComponent = require 'activity/components/appcomponent'

SingleChannelRoute = require 'activity/routes/SingleChannel'
SinglePrivateMessageRoute = require 'activity/routes/SinglePrivateMessage'

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

