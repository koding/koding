kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
formatPlural = kd.utils.formatPlural
classnames   = require 'classnames'

module.exports = class ChatPaneUnreadMessagesLabel extends React.Component

  @propsTypes =
    unreadCount  : React.PropTypes.number
    onJump       : React.PropTypes.func
    onMarkAsRead : React.PropTypes.func

  @defaultProps =
    unreadCount  : 0
    onJump       : kd.noop
    onMarkAsRead : kd.noop

  setPosition: (position) ->

    element = ReactDOM.findDOMNode this
    return  unless element

    return @close()  if position.visible

    element.className = classnames
      'ChatPane-unreadMessages' : yes
      'fixedOnTop'              : position.relativePosition is 'above'
      'fixedOnBottom'           : position.relativePosition is 'below'


  close: ->

    element = ReactDOM.findDOMNode this
    return  unless element

    element.classList.add 'out'


  onJump: (event) ->

    @close()
    @props.onJump()


  onMarkAsRead: (event) ->

    kd.utils.stopDOMEvent event
    @close()
    @props.onMarkAsRead()


  render: ->

    { unreadCount } = @props
    return null  unless unreadCount > 0

    <div className='ChatPane-unreadMessages fixedOnTop' onClick={@bound 'onJump'}>
      <span className='jumpButton'>Jump</span>
      <span className='counterText'>
        { "#{unreadCount} new #{formatPlural unreadCount, 'message', no}" }
      </span>
      <span className='markAsRead' onClick={@bound 'onMarkAsRead'}>Mark As Read (ESC)</span>
    </div>
