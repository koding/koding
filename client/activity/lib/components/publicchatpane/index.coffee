kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane        = require 'activity/components/chatpane'


module.exports = class PublicChatPane extends React.Component


  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()
    padded   : no


  componentDidMount: ->

    @createModalContainer()


  createModalContainer: ->

    ModalContainer = document.createElement 'div'
    ModalContainer.setAttribute 'class', 'PublicChatPane-ModalContainer hidden'
    document.body.appendChild ModalContainer


  channel: (key) -> @props.thread?.getIn ['channel', key]


  onSubmit: ({ value }) ->

    return  unless body = value
    name = @channel 'name'

    unless body.match ///\##{name}///
      body += " ##{name} "

    ActivityFlux.actions.message.createMessage @channel('id'), body


  onScrollThresholdReached: ->
    console.log "load messages"


  render: ->
    <ChatPane
      thread={@props.thread}
      className="PublicChatPane"
      title={@channel 'name'}
      messages={@props.messages}
      onSubmit={@bound 'onSubmit'}
      onScrollThresholdReached={@bound 'onScrollThresholdReached'}
    />


