kd           = require 'kd'
React        = require 'kd-react'
ReactDOM     = require 'react-dom'
formatPlural = kd.utils.formatPlural
classnames   = require 'classnames'

module.exports = class ChatPaneUnreadMessagesLabel extends React.Component

  @propsTypes =
    unreadCount : React.PropTypes.number

  @defaultProps =
    unreadCount : 0

  setPosition: (position) ->

    element = ReactDOM.findDOMNode this
    return  unless element

    element.className = classnames
      'ChatPane-unreadMessages' : yes
      'hidden'                  : position.visible
      'fixedOnTop'              : position.relativePosition is 'above'
      'fixedOnBottom'           : position.relativePosition is 'below'


  render: ->

    { unreadCount } = @props
    return null  unless unreadCount > 0

    <div className='ChatPane-unreadMessages fixedOnTop'>
      <span className='jumpButton'>Jump</span>
      <span className='counterText'>
        { "#{unreadCount} new #{formatPlural unreadCount, 'message', no}" }
      </span>
      <span className='markAsRead'>Mark As Read (ESC)</span>
    </div>
