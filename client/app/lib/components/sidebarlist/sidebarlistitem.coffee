kd         = require 'kd'
React      = require 'kd-react'
immutable  = require 'immutable'
classnames = require 'classnames'
Link       = require 'app/components/common/link'


module.exports = class SidebarListItem extends React.Component

  getClassName: ->
    classnames
      SidebarListItem : yes
      active          : @props.active


  renderUnreadCount: ->
    return null  unless @props.unreadCount > 0

    return \
      <cite className='SidebarListItem-unreadCount'>
        {@props.unreadCount}
      </cite>


  render: ->

    <div className={@getClassName()} onClick={@props.onClick}>
      <cite className='SidebarListItem-icon' />
      <Link className='SidebarListItem-link' href={@props.href}>
        {@props.title}
      </Link>
      {@renderUnreadCount()}
    </div>


