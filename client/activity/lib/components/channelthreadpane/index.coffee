kd                   = require 'kd'
React                = require 'kd-react'
KDReactorMixin       = require 'app/flux/base/reactormixin'
ActivityFlux         = require 'activity/flux'
immutable            = require 'immutable'
getGroup             = require 'app/util/getGroup'
classnames           = require 'classnames'
ThreadSidebar        = require 'activity/components/threadsidebar'
ThreadHeader         = require 'activity/components/threadheader'
PublicChannelLink    = require 'activity/components/publicchannellink'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
PublicChatPane       = require 'activity/components/publicchatpane'
showNotification     = require 'app/util/showNotification'
VideoComingSoonModal = require 'activity/components/videocomingsoonmodal'
ChannelDropContainer = require 'activity/components/channeldropcontainer'
Link                 = require 'app/components/common/link'


module.exports = class ChannelThreadPane extends React.Component

  { getters, actions } = ActivityFlux

  getDataBindings: ->
    return {
      channelThread       : getters.selectedChannelThread
      channelParticipants : getters.selectedChannelParticipants
    }


  constructor: (props) ->

    super props

    @state =
      showDropTarget        : no
      isComingSoonModalOpen : no
      channelThread         : immutable.Map()
      channelParticipants   : immutable.List()


  channel: (args...) -> @state.channelThread.getIn ['channel'].concat args


  onVideoStart: ->

    @setState isComingSoonModalOpen: yes


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


  onCollabModalClose: ->

    @setState isComingSoonModalOpen: no


  showNotificationSettingsModal: ->

    route = "/Channels/#{@channel 'name'}/NotificationSettings"
    kd.singletons.router.handleRoute route


  invitePeople: -> @refs.pane.onInviteOthers()


  leaveChannel: ->

    actions.channel.unfollowChannel @channel 'id'

    { unfollowChannel } = ActivityFlux.actions.channel
    unfollowChannel @channel 'id'


  renderHeader: ->

    return  unless thread = @state.channelThread

    <ThreadHeader
      className="ChannelThreadPane-header"
      thread={thread}
      onInvitePeople={@bound 'invitePeople'}
      onLeaveChannel={@bound 'leaveChannel'}
      onVideoStart={@bound 'onVideoStart'}
      onShowNotificationSettings={@bound 'showNotificationSettingsModal'}>
    </ThreadHeader>


  renderComingSoonModal: ->

    <CollaborationComingSoonModal
      onClose={@bound 'onCollabModalClose'}
      isOpen={@state.isComingSoonModalOpen}/>


  renderChannelDropContainer: ->

    <ChannelDropContainer
      onDrop={@bound 'onDrop'}
      onDragOver={@bound 'onDragOver'}
      onDragLeave={@bound 'onDragLeave'}
      showDropTarget={@state.showDropTarget}/>


  render: ->

    return null  unless thread = @state.channelThread

    <div className='ChannelThreadPane is-withChat'>
      {@renderComingSoonModal()}
      <section className='ChannelThreadPane-content'
        onDragEnter={@bound 'onDragEnter'}>
        {@renderChannelDropContainer()}
        {@renderHeader()}
        <div className='ChannelThreadPane-body'>
          <section className='ChannelThreadPane-chatWrapper'>
            <PublicChatPane ref='pane' thread={thread}/>
          </section>
        </div>
      </section>
      <aside className='ChannelThreadPane-sidebar'>
        <ThreadSidebar
          channelThread={thread}
          channelParticipants={@state.channelParticipants} />
      </aside>

      {@props.children}
    </div>


React.Component.include.call ChannelThreadPane, [
  KDReactorMixin, ImmutableRenderMixin
]

