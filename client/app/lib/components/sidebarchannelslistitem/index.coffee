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
      title={@props.channel.get 'name'}
      unreadCount={@props.channel.get 'unreadCount'}
      active={@props.active}
      href={prepareThreadLink @props.channel} />


prepareThreadLink = (channel) ->

  return null  unless channel

  return "/Channels/#{channel.get 'name'}"
