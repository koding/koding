kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ActivityFlux = require 'activity/flux'
ChatPane     = require 'activity/components/chatpane'
Modal        = require 'app/components/modal'


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


  onLoadMore: (event) ->

    return  unless @props.messages.size
    return  if @props.thread.getIn ['flags', 'isMessagesLoading']

    from = @props.messages.first().get('createdAt')
    kd.utils.defer =>
      ActivityFlux.actions.message.loadComments @message('id'), { from }


  render: ->
    <Modal isOpen={yes}>
      <ChatPane
        thread={@props.thread}
        className="PostPane"
        messages={@props.messages}
        onSubmit={@bound 'onSubmit'}
        onLoadMore={@bound 'onLoadMore'}
        isParticipant={@channel 'isParticipant'}
      />
    </Modal>


