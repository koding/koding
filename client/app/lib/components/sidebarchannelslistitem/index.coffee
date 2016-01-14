React           = require 'kd-react'
immutable       = require 'immutable'
SidebarListItem = require 'app/components/sidebarlist/sidebarlistitem'

module.exports = class SidebarChannelsListItem extends React.Component

  @propTypes =
    active  : React.PropTypes.bool
    channel : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    active  : no
    channel : immutable.Map()


  render: ->
    <SidebarListItem
      title={@channel 'name'}
      unreadCount={@channel 'unreadCount'}
      active={@props.active}
      href={prepareThreadLink @props.thread} />


prepareThreadLink = (thread) ->
  return null  unless thread

  return "/Channels/#{thread.getIn ['channel', 'name']}"
