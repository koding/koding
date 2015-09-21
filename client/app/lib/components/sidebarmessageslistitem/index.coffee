React                 = require 'kd-react'
SidebarListItem       = require 'app/components/sidebarlist/sidebarlistitem'
MessageListItemHelper = require 'activity/util/messageListItemHelper'

module.exports = class SidebarMessagesListItem extends React.Component

  channel: (key) -> @props.thread?.getIn ['channel', key]

  render: ->
    <SidebarListItem
      title={MessageListItemHelper.prepareThreadTitle @props.thread.get 'channel'}
      unreadCount={@channel 'unreadCount'}
      active={@props.active}
      href="/Messages/#{@channel 'id'}" />

