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
      channelThread         : immutable.Map()
      channelThreadMessages : immutable.List()
      messageThread         : immutable.Map()
      messageThreadComments : immutable.List()
      channelParticipants   : immutable.List()



  componentDidMount: -> reset @props


  componentWillReceiveProps: (nextProps) -> reset nextProps


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
      <section className="ChannelThreadPane-content">
        <header className="ChannelThreadPane-header">
          {@renderHeader()}
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

reset = (props) ->

  { channelName, postId } = props.routeParams
  { thread, channel: channelActions, message: messageActions } = ActivityFlux.actions

  if channelName
    channelActions.loadChannel('public', channelName).then ({ channel }) ->
      thread.changeSelectedThread channel.id
      channelActions.loadParticipants channel.id, channel.participantsPreview

      if postId
        messageActions.changeSelectedMessage postId
      else
        messageActions.changeSelectedMessage null

  else
    thread.changeSelectedThread null


