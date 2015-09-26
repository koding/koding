kd                       = require 'kd'
React                    = require 'kd-react'
PublicChatPane           = require 'activity/components/publicchatpane'
PublicFeedPane           = require 'activity/components/publicfeedpane'
ChannelThreadPane        = require 'activity/components/channelthreadpane'
PostPane                 = require 'activity/components/postpane'
PrivateMessageThreadPane = require 'activity/components/privatemessagethreadpane'

module.exports = [
  {
    path: '/Channels'
    component: ChannelThreadPane
    childRoutes: [
      path: ':channelName(/:postId)'
      components:
        chat: PublicChatPane
    ]
  },
  {
    path: '/Messages/:privateChannelId'
    component: PrivateMessageThreadPane
  }
]

