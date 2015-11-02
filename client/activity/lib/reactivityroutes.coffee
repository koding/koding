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

module.exports = [
  path: '/Channels'
  component: ActivityAppComponent
  childRoutes: [
    path: 'New'
    components:
      content: ChannelThreadPane
      modal: CreatePublicChannelModal
  ,
    path: 'All'
    components:
      content: ChannelThreadPane
      modal: BrowsePublicChannelsModal
  ,
    path: ':channelName(/:postId)'
    components:
      content: ChannelThreadPane
      modal: null
  ]
,
  path: '/Messages'
  component: ActivityAppComponent
  childRoutes: [
    path: 'New'
    components:
      content: PrivateMessageThreadPane
      modal: CreatePrivateChannelModal
  ,
    path: 'All'
    components:
      content: PrivateMessageThreadPane
      modal: BrowsePrivateChannelsModal
  ,
    path: ':privateChannelId(/:postId)'
    components:
      content: PrivateMessageThreadPane
      modal: null
  ]
]

