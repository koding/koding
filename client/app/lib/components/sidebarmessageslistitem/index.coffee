kd                   = require 'kd'
React                = require 'kd-react'
whoami               = require 'app/util/whoami'
isMyPost             = require 'app/util/isMyPost'
toImmutable          = require 'app/util/toImmutable'
MessageListItemHelper = require 'activity/util/messageListItemHelper'
SidebarListItem      = require 'app/components/sidebarlist/sidebarlistitem'
ProfileTextContainer = require 'app/components/profile/profiletextcontainer'


module.exports = class SidebarMessagesListItem extends React.Component

  channel: (key) -> @props.thread?.getIn ['channel', key]

  render: ->
    <SidebarListItem
      title={MessageListItemHelper.prepareThreadTitle @props.thread.get 'channel'}
      unreadCount={@channel 'unreadCount'}
      active={@props.active}
      href="/Messages/#{@channel 'id'}" />

