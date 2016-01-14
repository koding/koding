kd           = require 'kd'
React        = require 'kd-react'
immutable    = require 'immutable'
ActivityFlux = require 'activity/flux'
ChatPane     = require 'activity/components/chatpane'
Modal        = require 'app/components/modal'


module.exports = class PostPane extends React.Component

  @propTypes =
    thread        : React.PropTypes.instanceOf immutable.Map
    messages      : React.PropTypes.instanceOf immutable.List
    channelThread : React.PropTypes.instanceOf immutable.Map


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

    firstMessage = @props.messages.first()
    list = this.props.messages.remove this.props.messages.first().get 'id'
    from = list.first().get('createdAt')

    kd.utils.defer =>
      ActivityFlux.actions.message.loadComments @message('id'), { from }


  onFollowChannel: ->

    ActivityFlux.actions.channel.followChannel @channel('id')


  onClose: -> kd.singletons.router.handleRoute "/Channels/#{@channel 'name'}"


  render: ->
    <Modal className='PostPane-modal' isOpen={yes} onClose={@bound 'onClose'}>
      <ChatPane
        thread={@props.thread}
        className="PostPane"
        messages={@props.messages}
        onSubmit={@bound 'onSubmit'}
        onLoadMore={@bound 'onLoadMore'}
        isParticipant={@channel 'isParticipant'}
        onFollowChannelButtonClick={@bound 'onFollowChannel'}
        showItemMenu={no}
      />
    </Modal>
