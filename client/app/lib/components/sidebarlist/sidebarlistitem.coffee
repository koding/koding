kd         = require 'kd'
React      = require 'kd-react'
immutable  = require 'immutable'
classnames = require 'classnames'
Link       = require 'app/components/common/link'

module.exports = class SidebarListItem extends React.Component

  # title prop can be any type. SidebarChannelsListItem pass a string but
  # SidebarMessagesListItem can pass an object.
  @propTypes =
    title   : React.PropTypes.any
    href    : React.PropTypes.string
    onClick : React.PropTypes.func
    active  : React.PropTypes.bool


  @defaultProps =
    title   : ''
    href    : ''
    onClick : kd.noop
    active  : no


  constructor: (props) ->

    super props

    @state = { clicked: no }


  getClassName: -> classnames
    SidebarListItem : yes
    active          : @props.active ? @state.clicked


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
