kd                   = require 'kd'
React                = require 'kd-react'
KDReactorMixin       = require 'app/flux/reactormixin'
ActivityFlux         = require 'activity/flux'
immutable            = require 'immutable'
classnames           = require 'classnames'
ThreadSidebar        = require 'activity/components/threadsidebar'
ThreadHeader         = require 'activity/components/threadheader'
PublicChannelLink    = require 'activity/components/publicchannellink'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
PublicChatPane       = require 'activity/components/publicchatpane'
Link                 = require 'app/components/common/link'
Modal                = require 'app/components/modal'
showNotification     = require 'app/util/showNotification'


module.exports = class ChannelThreadPane extends React.Component

  @include [ ImmutableRenderMixin ]

  { getters } = ActivityFlux

  getDataBindings: ->
    return {
      channelThread         : getters.selectedChannelThread
      channelThreadMessages : getters.selectedChannelThreadMessages
      messageThread         : getters.selectedMessageThread
      messageThreadComments : getters.selectedMessageThreadComments
      channelParticipants   : getters.selectedChannelParticipants
    }


  constructor: (props) ->

    super props

    @state =
      showDropTarget        : no
      isComingSoonModalOpen : no
      channelThread         : immutable.Map()
      channelThreadMessages : immutable.List()
      messageThread         : immutable.Map()
      messageThreadComments : immutable.List()
      channelParticipants   : immutable.List()


  componentDidMount: -> reset @props, @state


  componentWillReceiveProps: (nextProps) -> reset nextProps, @state


  startVideoCall: ->

    @setState isComingSoonModalOpen: yes


  onDragEnter: (event)->

    kd.utils.stopDOMEvent event
    @setState showDropTarget: yes


  onDragOver: (event)-> kd.utils.stopDOMEvent event


  onDragLeave: (event)->

    kd.utils.stopDOMEvent event
    @setState showDropTarget: no


  onDrop: (event)->

    kd.utils.stopDOMEvent event
    @setState showDropTarget: no
    showNotification 'Coming soon...', type: 'main'


  getDropTargetClassNames: -> classnames
    'ChannelThreadPane-dropContainer': yes
    'hidden': not @state.showDropTarget


  onClose: ->

    @setState isComingSoonModalOpen: no


  renderComingSoonModal: ->

    if @state.isComingSoonModalOpen
      title = 'Coming Soon'
      <Modal className='ComingSoonModal' isOpen={yes} onClose={@bound 'onClose'}>
        <div className='ComingSoonModal-header'>
          <h3>COLLABORATE USING VIDEO CHAT</h3>
          <span>Coming really soon...</span>
        </div>
        <div className='ComingSoonModal-content'>
          <img src='/a/images/activity/coming-soon-modal-content.png'/>
        </div>
      </Modal>


  renderDropSection: ->

    <div
      onDrop={@bound 'onDrop'}
      onDragOver={@bound 'onDragOver'}
      onDragLeave={@bound 'onDragLeave'}
      className={@getDropTargetClassNames()}>
      <div>Drop VM's here<br/> to start collaborating</div>
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


  renderVideoCallArea: ->

    <Link className='ChannelThreadPane-videoCall' onClick={@bound 'startVideoCall'}>
      <span>Start a Video Call</span>
      <i className='ChannelThreadPane-videoCallIcon'></i>
    </Link>


  render: ->
    <div className="ChannelThreadPane is-withChat">
      {@renderComingSoonModal()}
      <section className="ChannelThreadPane-content"
        onDragEnter={@bound 'onDragEnter'}>
        {@renderDropSection()}
        <header className="ChannelThreadPane-header">
          {@renderHeader()}
          {@renderVideoCallArea()}
        </header>
        <div className="ChannelThreadPane-body">
          <section className="ChannelThreadPane-chatWrapper">
            <PublicChatPane
              thread={@state.channelThread}
              messages={@state.channelThreadMessages} />
          </section>
        </div>
      </section>
      <aside className="ChannelThreadPane-sidebar">
        <ThreadSidebar
          channelThread={@state.channelThread}
          channelParticipants={@state.channelParticipants}/>
      </aside>
    </div>


React.Component.include.call ChannelThreadPane, [KDReactorMixin]

reset = (props, state) ->

  { channelName, postId } = props.routeParams
  { thread, channel: channelActions, message: messageActions } = ActivityFlux.actions

  # if there is no channel in the url, and there is no selected channelThread,
  # then load public.
  unless channelName
    unless state.channelThread
      channelName = 'public'

  if channelName
    channel = ActivityFlux.getters.channelByName channelName
    thread.changeSelectedThread channel.id  if channel

    channelActions.loadChannel('public', channelName).then ({ channel }) ->
      thread.changeSelectedThread channel.id
      channelActions.loadParticipants channel.id, channel.participantsPreview
  else if not state.channelThread
    thread.changeSelectedThread null


