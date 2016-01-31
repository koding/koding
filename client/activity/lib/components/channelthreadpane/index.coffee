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
isKoding             = require 'app/util/isKoding'
nick                 = require 'app/util/nick'
AppearIn             = require 'app/components/appearin'
classnames           = require 'classnames'


module.exports = class ChannelThreadPane extends React.Component

  { getters, actions } = ActivityFlux

  getDataBindings: ->
    return {
      channelThread       : getters.selectedChannelThread
      popularChannels     : getters.popularChannels
      channelParticipants : getters.selectedChannelParticipants
    }


  constructor: (props) ->

    super props

    @state =
      showDropTarget      : no
      channelThread       : immutable.Map()
      channelParticipants : immutable.List()


  channel: (args...) -> @state.channelThread.getIn ['channel'].concat args


  showNotificationSettingsModal: ->

    route = "/Channels/#{@channel 'name'}/NotificationSettings"
    kd.singletons.router.handleRoute route


  invitePeople: -> @refs.pane.onInviteClick()


  onVideoStart: ->

    value = "@#{nick()} just joined the video session."

    ActivityFlux.actions.channel.startVideo @channel('id')
    ActivityFlux.actions.message.createMessage @channel('id'), value


  onVideoEnd: ->

    value = "@#{nick()} just left the video session."

    ActivityFlux.actions.channel.endVideo @channel('id')
    ActivityFlux.actions.message.createMessage @channel('id'), value


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

    isVideoActive = thread.getIn ['flags', 'isVideoActive']

    if not isKoding()
      <ChannelThreadHeader.Container
        className="ChannelThreadPane-header"
        thread={thread}
        isVideoActive={isVideoActive ? no}
        onInvitePeople={@bound 'invitePeople'}
        onLeaveChannel={@bound 'leaveChannel'}
        onVideoStart={@bound 'onVideoStart'}
        onVideoEnd={@bound 'onVideoEnd'}
        onShowNotificationSettings={@bound 'showNotificationSettingsModal'} />


  renderPaneByTypeConstant: (thread) ->

    if isKoding()
      <section className='ThreadPane-feedWrapper'>
        <PublicFeedPane
          ref='pane'
          thread={thread}
          popularChannels={@state.popularChannels}/>
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
    return null  if isKoding()

    <aside className='ChannelThreadPane-sidebar'>
      <ThreadSidebar
        channelThread={thread}
        channelParticipants={@state.channelParticipants} />
    </aside>


  renderVideo: ->

    isVideoActive = @state.channelThread.getIn ['flags', 'isVideoActive']

    videoName = "koding-#{getGroup().slug}-#{@channel 'id'}"

    <div className="ChannelThreadPane-videoContainer">
      {if isVideoActive then <AppearIn.Container name={videoName} />}
    </div>


  render: ->

    return null  unless thread = @state.channelThread

    className = classnames
      'ChannelThreadPane': yes
      'is-withChat': yes
      'is-withVideo': thread.getIn ['flags', 'isVideoActive']

    <div className={className}>
      <ChannelDropContainer className='ChannelThreadPane-content'>
        {@renderHeader()}
        {@renderVideo()}
        {@renderBody()}
      </ChannelDropContainer>
      {@renderSidebar()}
      {@props.children}
    </div>


React.Component.include.call ChannelThreadPane, [
  KDReactorMixin, ImmutableRenderMixin
]
