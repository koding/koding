React = require 'kd-react'
SidebarListItem = require 'app/components/sidebarlist/sidebarlistitem'


module.exports = class SidebarChannelsListItem extends React.Component

  channel: (key) -> @props.thread?.getIn ['channel', key]

  render: ->
    <SidebarListItem
      title={@channel 'name'}
      unreadCount={@channel 'unreadCount'}
      active={@props.active}
      href={prepareThreadLink @props.thread} />


prepareThreadLink = (thread) ->
  return null  unless thread

  return "/Channels/#{thread.getIn ['channel', 'name']}"
