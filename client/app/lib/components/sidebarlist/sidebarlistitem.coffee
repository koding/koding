kd         = require 'kd'
React      = require 'kd-react'
immutable  = require 'immutable'
classnames = require 'classnames'
Link       = require 'app/components/common/link'


module.exports = class SidebarListItem extends React.Component

  constructor: (props) ->
    super props

    @state = { clicked: no }


  getClassName: ->
    classnames
      SidebarListItem        : yes
      active                 : @props.active ? @state.clicked


  renderUnreadCount: ->
    return null  unless @props.unreadCount > 0

    return \
      <cite className='SidebarListItem-unreadCount'>
        {@props.unreadCount}
      </cite>


  onClick: (args...) ->

    @setState { clicked: yes }, => @props.onClick? args...


  render: ->

    <Link className={@getClassName()} href={@props.href} onClick={@bound 'onClick'}>
      <cite className='SidebarListItem-icon' />
      <span className='SidebarListItem-title'>{@props.title}</span>
      {@renderUnreadCount()}
    </Link>
