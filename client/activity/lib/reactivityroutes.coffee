kd                = require 'kd'
React             = require 'kd-react'
PublicChatPane    = require 'activity/components/publicchatpane'
PublicFeedPane    = require 'activity/components/publicfeedpane'
ChannelThreadPane = require 'activity/components/channelthreadpane'

module.exports =
  path: '/Activity/Channels'
  component: ChannelThreadPane
  childRoutes: [
    path: ':slug/feed'
    components:
      feed: PublicFeedPane
      chat: null
  ,
    path: ':slug/feed-chat'
    components:
      feed: PublicFeedPane
      chat: PublicChatPane
  ,
    path: ':slug'
    components:
      feed: null
      chat: PublicChatPane
  ]


