kd                   = require 'kd'
React                = require 'kd-react'
toImmutable          = require 'app/util/toImmutable'
SidebarListItem      = require 'app/components/sidebarlist/sidebarlistitem'
prepareThreadTitle   = require 'activity/util/prepareThreadTitle'

module.exports = class SidebarMessagesListItem extends React.Component

  channel: (key) -> @props.thread?.getIn ['channel', key]

  render: ->
    <SidebarListItem
      title={prepareThreadTitle @props.thread}
      unreadCount={@channel 'unreadCount'}
      active={@props.active}
      href="/Messages/#{@channel 'id'}" />
