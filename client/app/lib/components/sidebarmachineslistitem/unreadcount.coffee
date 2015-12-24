React = require 'kd-react'


module.exports = class UnreadCount extends React.Component

  @defaultProps =
    count : 0

  render: ->

    return null  unless @props.count

    <cite className='SidebarListItem-unreadCount'>
      {@props.count}
    </cite>

