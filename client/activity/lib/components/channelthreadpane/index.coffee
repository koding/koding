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
      channelThread         : immutable.Map()
      channelParticipants   : immutable.List()


  channel: (args...) -> @state.channelThread.getIn ['channel'].concat args


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
      onShowNotificationSettings={@bound 'showNotificationSettingsModal'}>
    </ThreadHeader>


  renderChannelDropContainer: ->

    <ChannelDropContainer
      onDrop={@bound 'onDrop'}
      onDragOver={@bound 'onDragOver'}
      onDragLeave={@bound 'onDragLeave'}
      showDropTarget={@state.showDropTarget}/>


  renderBody: ->

    <div className='ChannelThreadPane-body'>
      <section className='ChannelThreadPane-chatWrapper'>
        <PublicChatPane ref='pane' thread={thread}/>
      </section>
    </div>


  renderSidebar: ->

    <ThreadSidebar
      channelThread={thread}
      channelParticipants={@state.channelParticipants} />


  render: ->

    return null  unless thread = @state.channelThread

    <div className='ChannelThreadPane is-withChat'>
      <section className='ChannelThreadPane-content'
        onDragEnter={@bound 'onDragEnter'}>
        {@renderChannelDropContainer()}
        {@renderHeader()}
        {@renderBody()}
      </section>
      <aside className='ChannelThreadPane-sidebar'>
        {@renderSidebar()}
      </aside>
    </div>


React.Component.include.call ChannelThreadPane, [
  KDReactorMixin, ImmutableRenderMixin
]

