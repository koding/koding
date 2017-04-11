kd    = require 'kd'
React = require 'app/react'

module.exports = UnreadCount = ({ count = 0, onClick = kd.noop }) ->

  if not count
    return null

  <cite className='SidebarListItem-unreadCount' onClick={onClick}>
    {count}
  </cite>
