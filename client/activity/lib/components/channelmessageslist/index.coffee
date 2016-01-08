kd            = require 'kd'
React         = require 'kd-react'
Link          = require 'app/components/common/link'
immutable     = require 'immutable'
formatContent = require 'app/util/formatContent'
emojify       = require 'emojify.js'
MessageLink   = require 'activity/components/messagelink'
MessageBody   = require 'activity/components/common/messagebody'

module.exports = class ChannelMessagesList extends React.Component

  @defaultProps =
    thread: null
    messages: null
    maxCount: 10


  renderBody: ->


  renderChildren: ->
    return null  unless @props.messages

    @props.messages.slice(0, @props.maxCount).map (message) ->
      <li key={message.get 'id'} className="ChannelMessagesList-messageItem">
        <MessageLink
          message={message}
          dangerouslySetInnerHTML={__html: helper.renderBody message}
        />
      </li>


  render: ->
    <ul className="ChannelMessagesList">
      {@renderChildren()}
    </ul>


helper =

  renderBody: (message) ->
    e = document.createElement 'div'
    e.innerHTML = formatContent message.get 'body'
    body = e.textContent or e.innerText
    body = emojify.replace body
