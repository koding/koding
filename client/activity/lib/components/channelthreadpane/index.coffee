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
ThreadPaneLifecycleMixin     = require 'activity/mixins/threadpanelifecycle'

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
    <div className="ChannelThreadPane is-withChat">
      <CollaborationComingSoonModal
        onClose={@bound 'onClose'}
        isOpen={@state.isComingSoonModalOpen}/>
      <section className="ChannelThreadPane-content"
        onDragEnter={@bound 'onDragEnter'}>
        <ChannelDropContainer
          onDrop={@bound 'onDrop'}
          onDragOver={@bound 'onDragOver'}
          onDragLeave={@bound 'onDragLeave'}
          showDropTarget={@state.showDropTarget}/>
        <header className="ChannelThreadPane-header">
          {@renderHeader()}
          <StartVideoCallLink onStart={@bound 'onStart'}/>
        </header>
        <div className="ChannelThreadPane-body">
          <section className="ChannelThreadPane-chatWrapper">
            <PublicChatPane ref='pane' thread={@state.channelThread}/>
          </section>
        </div>
      </section>
      <aside className="ChannelThreadPane-sidebar">
        <ThreadSidebar
          channelThread={@state.channelThread}
          channelParticipants={@state.channelParticipants}/>
      </aside>
    </div>


React.Component.include.call ChannelThreadPane, [
  KDReactorMixin, ImmutableRenderMixin
]

