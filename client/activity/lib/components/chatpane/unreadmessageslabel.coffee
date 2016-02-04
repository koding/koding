kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
formatPlural = kd.utils.formatPlural
classnames   = require 'classnames'

module.exports = class ChatPaneUnreadMessagesLabel extends React.Component

  @propsTypes =
    unreadCount           : React.PropTypes.number
    onJump                : React.PropTypes.func
    onMarkAsRead          : React.PropTypes.func
    unreadMessagePosition : React.PropTypes.string

  @defaultProps =
    unreadCount           : 0
    onJump                : kd.noop
    onMarkAsRead          : kd.noop
    unreadMessagePosition : null


  componentDidMount: -> @setPosition()


  componentDidUpdate: -> @setPosition()


  setPosition: ->

    { unreadMessagePosition } = @props

    element = ReactDOM.findDOMNode this
    return  unless element

    isAbove = unreadMessagePosition is 'above'
    isBelow = unreadMessagePosition is 'below'

    return @close()  unless isAbove or isBelow

    element.className = classnames
      'ChatPane-unreadMessages' : yes
      'fixedOnTop'              : isAbove
      'fixedOnBottom'           : isBelow


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

    <div className='ChatPane-unreadMessages' onClick={@bound 'onJump'}>
      <span className='jumpButton'>Jump</span>
      <span className='counterText'>
        { "#{unreadCount} new #{formatPlural unreadCount, 'message', no}" }
      </span>
      <span className='markAsRead' onClick={@bound 'onMarkAsRead'}>Mark As Read (ESC)</span>
    </div>
