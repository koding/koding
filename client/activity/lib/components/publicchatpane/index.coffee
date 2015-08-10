kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ActivityFlux    = require 'activity/flux'
ChatPane        = require 'activity/components/chatpane'


module.exports = class PublicChatPane extends React.Component
  constructor: (options = {}, data) ->

    @state = { skip : 0 }


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

    @state.skip += 25

    ActivityFlux.actions.message.loadMessages @channel('id'), @state.skip


  render: ->
    <ChatPane
      thread={@props.thread}
      className="PublicChatPane"
      messages={@props.messages}
      onSubmit={@bound 'onSubmit'}
      onScrollThresholdReached={@bound 'onScrollThresholdReached'}
    />


