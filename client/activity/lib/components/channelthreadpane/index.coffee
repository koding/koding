kd                   = require 'kd'
React                = require 'kd-react'
KDReactorMixin       = require 'app/flux/base/reactormixin'
ActivityFlux         = require 'activity/flux'
immutable            = require 'immutable'
ThreadSidebar        = require 'activity/components/threadsidebar'
ChannelThreadHeader  = require 'activity/components/channelthreadheader'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
PublicChatPane       = require 'activity/components/publicchatpane'
PublicFeedPane       = require 'activity/components/publicfeedpane'
ChannelDropContainer = require 'activity/components/channeldropcontainer'
getGroup             = require 'app/util/getGroup'
isFeedEnabled        = require 'app/util/isFeedEnabled'
FeedThreadSidebar    = require 'activity/components/publicfeedpane/feedthreadsidebar'


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
      channelThread         : immutable.Map()
      channelParticipants   : immutable.List()


  channel: (args...) -> @state.channelThread.getIn ['channel'].concat args


  showNotificationSettingsModal: ->

    route = "/Channels/#{@channel 'name'}/NotificationSettings"
    kd.singletons.router.handleRoute route


  invitePeople: -> @refs.pane.onInviteOthers()


  leaveChannel: ->

    channelId = @channel 'id'

    if @channel('typeConstant') is "privatemessage"
      actions.channel.leavePrivateChannel channelId
        .then ->
          channelName = getGroup().slug
          kd.singletons.router.handleRoute "/Channels/#{channelName}"
    else
      actions.channel.unfollowChannel channelId


  renderHeader: ->

    return  unless thread = @state.channelThread

    if not isFeedEnabled()
      <ChannelThreadHeader
        className="ChannelThreadPane-header"
        thread={thread}
        onInvitePeople={@bound 'invitePeople'}
        onLeaveChannel={@bound 'leaveChannel'}
        onShowNotificationSettings={@bound 'showNotificationSettingsModal'}>
      </ChannelThreadHeader>


  renderPaneByTypeConstant: (thread) ->

    if isFeedEnabled()
      <section className='ThreadPane-feedWrapper'>
        <PublicFeedPane ref='pane' thread={thread}/>
      </section>
    else
      <section className='ThreadPane-chatWrapper'>
        <PublicChatPane ref='pane' thread={thread}/>
      </section>


  renderBody: ->

    return null  unless thread = @state.channelThread

    <div className='ChannelThreadPane-body'>
      {@renderPaneByTypeConstant(thread)}
    </div>


  renderSidebar: ->

    return null  unless thread = @state.channelThread

    if isFeedEnabled()
      <aside className='FeedThreadPane-sidebar'>
        <FeedThreadSidebar
          channelThread={thread} />
      </aside>
    else
      <aside className='ChannelThreadPane-sidebar'>
        <ThreadSidebar
          channelThread={thread}
          channelParticipants={@state.channelParticipants} />
      </aside>


  render: ->

    return null  unless thread = @state.channelThread

    <div className='ChannelThreadPane is-withChat'>
      <ChannelDropContainer className='ChannelThreadPane-content'>
        {@renderHeader()}
        {@renderBody()}
      </ChannelDropContainer>
      {@renderSidebar()}
      {@props.children}
    </div>


React.Component.include.call ChannelThreadPane, [
  KDReactorMixin, ImmutableRenderMixin
]

