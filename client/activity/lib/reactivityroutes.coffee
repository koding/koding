kd                = require 'kd'
React             = require 'kd-react'
{ Route }         = require 'react-router'
PublicChatPane    = require 'activity/components/publicchatpane'
PublicFeedPane    = require 'activity/components/publicfeedpane'
ChannelThreadPane = require 'activity/components/channelthreadpane'

module.exports = \
  <Route path="/Activity/Channels/" component={ChannelThreadPane}>
    <Route path=":slug/feed" components={{ feed: PublicFeedPane, chat: null }} />
    <Route path=":slug/feed-chat" components={{ feed: PublicFeedPane, chat: PublicChatPane }} />
    <Route path=":slug" components={{ feed: null, chat: PublicChatPane }} />
  </Route>


