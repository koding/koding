kd          = require 'kd'
React       = require 'kd-react'
Link        = require 'app/components/common/link'
immutable   = require 'immutable'
formatContent = require 'app/util/formatContent'

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
        <Link href="/Channels/Public/#{message.get 'slug'}">
          {helper.renderBody message}
        </Link>
      </li>


  render: ->
    <ul className="ChannelMessagesList">
      {@renderChildren()}
    </ul>


helper =

  renderBody: (message) ->
    e = document.createElement 'div'
    e.innerHTML = formatContent message.get 'body'
    return e.textContent or e.innerText

