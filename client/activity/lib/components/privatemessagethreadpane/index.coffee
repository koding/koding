kd                        = require 'kd'
React                     = require 'kd-react'
KDReactorMixin            = require 'app/flux/reactormixin'
ActivityFlux              = require 'activity/flux'
immutable                 = require 'immutable'
classnames                = require 'classnames'
PrivateChatPane           = require 'activity/components/privatechatpane'
ThreadSidebarContentBox   = require 'activity/components/threadsidebarcontentbox'
ChannelParticipantAvatars = require 'activity/components/channelparticipantavatars'
prepareThreadTitle        = require 'activity/util/prepareThreadTitle'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class PrivateMessageThreadPane extends React.Component

  @include [ImmutableRenderMixin]

  { getters } = ActivityFlux

  getDataBindings: ->

    return {
      channelThread         : getters.selectedChannelThread
      channelThreadMessages : getters.selectedChannelThreadMessages
      channelParticipants   : getters.selectedChannelParticipants
      followedChannels      : getters.followedPrivateChannelThreads
    }


  constructor: (props) ->

    super props

    @state =
      channelThread         : immutable.Map()
      channelThreadMessages : immutable.List()
      channelParticipants   : immutable.List()


  componentDidMount: -> reset @props, @state


  componentWillReceiveProps: (nextProps) -> reset nextProps, @state


  renderHeader: ->

    return  unless @state.channelThread

    prepareThreadTitle @state.channelThread


  renderChat: ->

    <PrivateChatPane
      thread   = { @state.channelThread }
      messages = { @state.channelThreadMessages }
    />


  renderSidebar: ->

    <div className="ThreadSidebar">
      <ThreadSidebarContentBox title="Participants">
        <ChannelParticipantAvatars
          channelThread = { @state.channelThread }
          participants  = { @state.channelParticipants }
        />
      </ThreadSidebarContentBox>
    </div>


  render: ->
    <div className='PrivateMessageThreadPane'>
      <section className="PrivateMessageThreadPane-content">
        <header className="PrivateMessageThreadPane-header">
          {@renderHeader()}
        </header>
        <div className="PrivateMessageThreadPane-body">
          <section className="PrivateMessageThreadPane-chatWrapper">
            {@renderChat()}
          </section>
        </div>
      </section>
      <aside className="PrivateMessageThreadPane-sidebar">
        {@renderSidebar()}
      </aside>
    </div>


React.Component.include.call PrivateMessageThreadPane, [KDReactorMixin]

reset = (props, state) ->

  { followedChannels, channelThread } = state
  { privateChannelId } = props.routeParams
  {
    thread : threadActions,
    channel : channelActions,
    message : messageActions } = ActivityFlux.actions

  unless privateChannelId
    unless channelThread
      botChannel = kd.singletons.socialapi.getPrefetchedData 'bot'
      privateChannelId = botChannel.id

  if privateChannelId
    channelActions.loadChannel('private', privateChannelId).then ({ channel }) ->
      threadActions.changeSelectedThread channel.id
      channelActions.loadParticipants channel.id, channel.participantsPreview
  else if not channelThread
    threadActions.changeSelectedThread null

