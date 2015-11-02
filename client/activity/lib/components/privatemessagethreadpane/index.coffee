kd                           = require 'kd'
React                        = require 'kd-react'
KDReactorMixin               = require 'app/flux/base/reactormixin'
ActivityFlux                 = require 'activity/flux'
immutable                    = require 'immutable'
classnames                   = require 'classnames'
PrivateChatPane              = require 'activity/components/privatechatpane'
ThreadSidebarContentBox      = require 'activity/components/threadsidebarcontentbox'
ChannelParticipantAvatars    = require 'activity/components/channelparticipantavatars'
ThreadSidebar                = require 'activity/components/threadsidebar'
prepareThreadTitle           = require 'activity/util/prepareThreadTitle'
ImmutableRenderMixin         = require 'react-immutable-render-mixin'
StartVideoCallLink           = require 'activity/components/common/startvideocalllink'
CollaborationComingSoonModal = require 'activity/components/collaborationcomingsoonmodal'
showNotification             = require 'app/util/showNotification'
ChannelDropContainer         = require 'activity/components/channeldropcontainer'
ThreadPaneLifecycleMixin     = require 'activity/mixins/threadpanelifecycle'


module.exports = class PrivateMessageThreadPane extends React.Component

  { getters } = ActivityFlux

  getDataBindings: ->

    return {
      channelThread         : getters.selectedChannelThread
      channelParticipants   : getters.selectedChannelParticipants
      followedChannels      : getters.followedPrivateChannelThreads
    }


  constructor: (props) ->

    super props

    @state =
      showDropTarget        : no
      channelThread         : immutable.Map()
      channelParticipants   : immutable.List()
      isComingSoonModalOpen : no


  onStart: ->

    @setState isComingSoonModalOpen: yes


  onClose: ->

    @setState isComingSoonModalOpen: no


  renderHeader: ->

    return  unless @state.channelThread

    prepareThreadTitle @state.channelThread


  onDragEnter: (event) ->

    kd.utils.stopDOMEvent event
    @setState showDropTarget: yes


  onDragOver: (event) -> kd.utils.stopDOMEvent event


  onDragLeave: (event) ->

    kd.utils.stopDOMEvent event
    @setState showDropTarget: no


  onDrop: (event) ->

    kd.utils.stopDOMEvent event
    @setState showDropTarget: no
    showNotification 'Coming soon...', type: 'main'


  render: ->
    <div className='PrivateMessageThreadPane'>
      <CollaborationComingSoonModal
        onClose={@bound 'onClose'}
        isOpen={@state.isComingSoonModalOpen}/>
      <section className='PrivateMessageThreadPane-content'
        onDragEnter={@bound 'onDragEnter'}>
        <ChannelDropContainer
          onDrop={@bound 'onDrop'}
          onDragOver={@bound 'onDragOver'}
          onDragLeave={@bound 'onDragLeave'}
          showDropTarget={@state.showDropTarget}/>
        <header className='PrivateMessageThreadPane-header'>
          {@renderHeader()}
          <StartVideoCallLink onStart={@bound 'onStart'}/>
        </header>
        <div className='PrivateMessageThreadPane-body'>
          <section className='PrivateMessageThreadPane-chatWrapper'>
            <PrivateChatPane ref='pane' thread={ @state.channelThread }/>
          </section>
        </div>
      </section>
      <aside className='PrivateMessageThreadPane-sidebar'>
        <ThreadSidebar
          channelThread={@state.channelThread}
          channelParticipants={@state.channelParticipants}/>
      </aside>
    </div>


reset = (props, state, callback = kd.noop) ->

  { followedChannels, channelThread } = state
  { privateChannelId, postId}         = props.routeParams
  {
    thread : threadActions,
    channel : channelActions,
    message : messageActions } = ActivityFlux.actions

  unless privateChannelId
    unless channelThread
      botChannel = kd.singletons.socialapi.getPrefetchedData 'bot'
      privateChannelId = botChannel.id

  if privateChannelId
    channelActions.loadChannel(privateChannelId).then ({ channel }) ->
      threadActions.changeSelectedThread channel.id
      channelActions.loadParticipants channel.id, channel.participantsPreview
    if postId
      messageActions.changeSelectedMessage postId
    else
      messageActions.changeSelectedMessage null

    kd.utils.defer callback

  else if not channelThread
    threadActions.changeSelectedThread null
    kd.utils.defer callback


React.Component.include.call PrivateMessageThreadPane, [
  ThreadPaneLifecycleMixin(reset), KDReactorMixin, ImmutableRenderMixin
]

