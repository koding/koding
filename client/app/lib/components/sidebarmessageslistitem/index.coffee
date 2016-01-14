kd                 = require 'kd'
React              = require 'kd-react'
immutable          = require 'immutable'
SidebarListItem    = require 'app/components/sidebarlist/sidebarlistitem'
prepareThreadTitle = require 'activity/util/prepareThreadTitle'

module.exports = class SidebarMessagesListItem extends React.Component

  @propTypes =
    active  : React.PropTypes.bool
    channel : React.PropTypes.instanceOf immutable.Map


  @defaultProps =
    active  : no
    channel : immutable.Map()


  render: ->
    <SidebarListItem
      title={prepareThreadTitle @props.thread}
      unreadCount={@channel 'unreadCount'}
      active={@props.active}
      href="/Messages/#{@channel 'id'}" />
