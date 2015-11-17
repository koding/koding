kd                           = require 'kd'
React                        = require 'kd-react'
KDReactorMixin               = require 'app/flux/base/reactormixin'
ActivityFlux                 = require 'activity/flux'
immutable                    = require 'immutable'
getGroup                     = require 'app/util/getGroup'
classnames                   = require 'classnames'
ThreadSidebar                = require 'activity/components/threadsidebar'
ThreadHeader                 = require 'activity/components/threadheader'
PublicChannelLink            = require 'activity/components/publicchannellink'
ImmutableRenderMixin         = require 'react-immutable-render-mixin'
PublicChatPane               = require 'activity/components/publicchatpane'
showNotification             = require 'app/util/showNotification'
CollaborationComingSoonModal = require 'activity/components/collaborationcomingsoonmodal'
StartVideoCallLink           = require 'activity/components/common/startvideocalllink'
ChannelDropContainer         = require 'activity/components/channeldropcontainer'
Link                         = require 'app/components/common/link'
ButtonWithMenu               = require 'app/components/buttonwithmenu'
KeyboardKeys                 = require 'app/util/keyboardKeys'

module.exports = class ChannelThreadPane extends React.Component

  { getters } = ActivityFlux

  getDataBindings: ->
    return {
      channelThread         : getters.selectedChannelThread
      messageThread         : getters.selectedMessageThread
      messageThreadComments : getters.selectedMessageThreadComments
      channelParticipants   : getters.selectedChannelParticipants
    }


  constructor: (props) ->

    super props

    @state =
      originalPurpose       : ''
      showDropTarget        : no
      isComingSoonModalOpen : no
      channelThread         : immutable.Map()
      messageThread         : immutable.Map()
      messageThreadComments : immutable.List()
      channelParticipants   : immutable.List()


  onStart: ->

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


  onClose: ->

    @setState isComingSoonModalOpen: no


  getMenuItems: ->
    return [
      {title: 'Invite people'         , key: 'invitepeople'         , onClick: @bound 'invitePeople'}
      {title: 'Leave channel'         , key: 'leavechannel'         , onClick: @bound 'leaveChannel'}
      {title: 'Update purpose'        , key: 'updatepurpose'        , onClick: @bound 'updatePurpose'}
      {title: 'Notification settings' , key: 'notificationsettings' , onClick: @bound 'showNotificationSettingsModal'}
    ]


  invitePeople: -> @refs.pane.onInviteOthers()


  leaveChannel: ->

    { unfollowChannel } = ActivityFlux.actions.channel
    channelId   = @state.channelThread.get 'channelId'

    unfollowChannel channelId


  updatePurpose: ->

    channelThread = @state.channelThread.set 'editingPurpose', yes
    @setState channelThread: channelThread

    input = @refs.purposeInput

    kd.utils.defer ->
      kd.utils.moveCaretToEnd input


  showNotificationSettingsModal: ->

    channelName = @state.channelThread.getIn ['channel', 'name']
    route = "/Channels/#{channelName}/NotificationSettings"

    kd.singletons.router.handleRoute route


  onKeyDown: (event) ->

    { ENTER, ESC } = KeyboardKeys
    thread         = @state.channelThread
    purpose        = thread.getIn(['channel', 'purpose'])

    if event.which is ESC

      _originalPurpose = thread.getIn ['channel', '_originalPurpose']
      purpose = _originalPurpose or thread.getIn ['channel', 'purpose']
      thread  = thread.setIn ['channel', 'purpose'], purpose
      thread  = thread.set 'editingPurpose', no
      return @setState channelThread: thread

    if event.which is ENTER

      id        = thread.get 'channelId'
      purpose   = thread.getIn(['channel', 'purpose']).trim()

      { updateChannel } = ActivityFlux.actions.channel

      updateChannel({ id, purpose }).then (response) =>
        thread  = thread.set 'editingPurpose', no
        return @setState channelThread: thread


  getPurposeAreaClassNames: -> classnames
    'ChannelThreadPane-purposeWrapper': yes
    'editing': @state.channelThread.get 'editingPurpose'


  handleChange: (newValue) ->

    thread = @state.channelThread

    unless thread.getIn ['channel', '_originalPurpose']
      _originalPurpose = thread.getIn ['channel', 'purpose']
      thread = thread.setIn ['channel', '_originalPurpose'], _originalPurpose

    channelThread = thread.setIn ['channel', 'purpose'], newValue
    @setState channelThread: channelThread


  renderPurposeArea: ->

    return  unless @state.channelThread

    thread = @state.channelThread

    valueLink =
      value: thread.getIn ['channel', 'purpose']
      requestChange: @bound 'handleChange'

    <div className={@getPurposeAreaClassNames()}>
      <span className='ChannelThreadPane-purpose'>{thread.getIn ['channel', 'purpose']}</span>
      <input ref='purposeInput' type='text' valueLink={valueLink} onKeyDown={@bound 'onKeyDown'} />
    </div>


  renderHeader: ->

    return  unless @state.channelThread
    thread = @state.channelThread
    channelName = thread.getIn ['channel', 'name']

    <ThreadHeader thread={thread}>
      <PublicChannelLink to={thread}>
        {"##{channelName}"}
      </PublicChannelLink>
    </ThreadHeader>


  render: ->

    return null  unless @state.channelThread
    thread = @state.channelThread
    channelName = thread.getIn ['channel', 'name']

    <div className='ChannelThreadPane is-withChat'>
      <CollaborationComingSoonModal
        onClose={@bound 'onClose'}
        isOpen={@state.isComingSoonModalOpen}/>
      <section className='ChannelThreadPane-content'
        onDragEnter={@bound 'onDragEnter'}>
        <ChannelDropContainer
          onDrop={@bound 'onDrop'}
          onDragOver={@bound 'onDragOver'}
          onDragLeave={@bound 'onDragLeave'}
          showDropTarget={@state.showDropTarget}/>
        <header className='ChannelThreadPane-header'>
          {@renderHeader()}
          <ButtonWithMenu listClass='ChannelThreadPane-menuItems' items={@getMenuItems()} />
          {@renderPurposeArea()}
          <StartVideoCallLink onStart={@bound 'onStart'}/>
        </header>
        <div className='ChannelThreadPane-body'>
          <section className='ChannelThreadPane-chatWrapper'>
            <PublicChatPane ref='pane' thread={@state.channelThread}/>
          </section>
        </div>
      </section>
      <aside className='ChannelThreadPane-sidebar'>
        <ThreadSidebar
          channelThread={@state.channelThread}
          channelParticipants={@state.channelParticipants}/>
      </aside>

      {@props.children}
    </div>


React.Component.include.call ChannelThreadPane, [
  KDReactorMixin, ImmutableRenderMixin
]

