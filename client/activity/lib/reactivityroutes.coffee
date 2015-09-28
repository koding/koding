kd                       = require 'kd'
React                    = require 'kd-react'
PublicChatPane           = require 'activity/components/publicchatpane'
PublicFeedPane           = require 'activity/components/publicfeedpane'
ChannelThreadPane        = require 'activity/components/channelthreadpane'
PostPane                 = require 'activity/components/postpane'
PrivateMessageThreadPane = require 'activity/components/privatemessagethreadpane'

ActivityAppComponent = require 'activity/components/appcomponent'

# module.exports = [
#   {
#     path: '/Channels'
#     component: ChannelThreadPane
#     childRoutes: [
#       path: ':channelName(/:postId)'
#       components:
#         chat: PublicChatPane
#     ]
#   },
#   {
#     path: '/Messages/:privateChannelId'
#     component: PrivateMessageThreadPane
#   }
# ]


module.exports = newRoutes = [
  path: '/Channels'
  component: ActivityAppComponent
  childRoutes: [
    path: ':channelName(/:postId)'
    components:
      content: ChannelThreadPane
      modal: null
  ,
    path: 'New'
    components:
      content: ChannelThreadPane
      modal: null
  ]
,
  path: '/Messages'
  component: ActivityAppComponent
  childRoutes: [
    path: ':privateChannelId'
    components:
      content: PrivateMessageThreadPane
      modal: null
  ,
    path: 'New'
    components:
      content: PrivateMessageThreadPane
      modal: null
  ]
]

