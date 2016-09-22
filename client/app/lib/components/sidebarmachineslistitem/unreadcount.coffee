kd    = require 'kd'
React = require 'app/react'


module.exports = class UnreadCount extends React.Component

  @defaultProps =
    count   : 0
    onClick : kd.noop


  handleOnClick: ->
    @props.onClick()


  render: ->

    return null  unless @props.count

    <cite className='SidebarListItem-unreadCount' onClick={@bound 'handleOnClick'}>
      {@props.count}
    </cite>
