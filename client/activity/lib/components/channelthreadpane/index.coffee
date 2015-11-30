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
Encoder                      = require 'htmlencode'


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
      editingPurpose        : no
      originalPurpose       : ''
      showDropTarget        : no
      isComingSoonModalOpen : no
      channelThread         : immutable.Map()
      messageThread         : immutable.Map()
      messageThreadComments : immutable.List()
      channelParticipants   : immutable.List()


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


  componentWillUpdate: (nextProps, nextState) ->

    return  unless @state.channelThread and nextState.channelThread

    channelId          = @state.channelThread.get 'channelId'
    nextStateChannelId = nextState.channelThread.get 'channelId'

    return @setState editingPurpose: no  if channelId isnt nextStateChannelId


  updatePurpose: ->

    @setState editingPurpose: yes

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
      @setState channelThread: thread
      return @setState editingPurpose: no

    if event.which is ENTER

      id        = thread.get 'channelId'
      purpose   = thread.getIn(['channel', 'purpose']).trim()

      { updateChannel } = ActivityFlux.actions.channel

      updateChannel({ id, purpose }).then (response) =>
        @setState editingPurpose: no


  getPurposeAreaClassNames: -> classnames
    'ChannelThreadPane-purposeWrapper': yes
    'editing': @state.editingPurpose


  handlePurposeInputChange: (newValue) ->

    thread = @state.channelThread

    unless thread.getIn ['channel', '_originalPurpose']
      _originalPurpose = thread.getIn ['channel', 'purpose']
      thread = thread.setIn ['channel', '_originalPurpose'], _originalPurpose

    channelThread = thread.setIn ['channel', 'purpose'], newValue
    @setState channelThread: channelThread


  renderPurposeArea: ->

    return  unless @state.channelThread

    purpose = @state.channelThread.getIn ['channel', 'purpose']
    purpose = Encoder.htmlDecode purpose

    valueLink =
      value         : purpose
      requestChange : @bound 'handlePurposeInputChange'

    <div className={@getPurposeAreaClassNames()}>
      <span className='ChannelThreadPane-purpose'>{purpose}</span>
      <input
        ref='purposeInput'
        type='text'
        valueLink={valueLink}
        onKeyDown={@bound 'onKeyDown'} />
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
        onClose={@bound 'onCollabModalClose'}
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
          <StartVideoCallLink onStart={@bound 'onVideoStart'}/>
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

