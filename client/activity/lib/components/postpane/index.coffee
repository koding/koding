kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane = require 'activity/components/chatpane'


module.exports = class PostPane extends React.Component

  @defaultProps =
    thread        : immutable.Map()
    messages      : immutable.List()
    channelThread : immutable.Map()


  channel: (key) -> @props.channelThread?.getIn ['channel', key]


  message: (key) -> @props.thread?.getIn ['message', key]


  onSubmit: (event) ->

    return  unless event.value

    ActivityFlux.actions.message.createComment @message('id'), event.value


  render: ->
    <ChatPane
      className="PostPane"
      title={"#{@channel 'name'}/#{@message 'slug'}"}
      messages={@props.messages}
      onSubmit={@bound 'onSubmit'}
    />


