kd             = require 'kd'
React          = require 'kd-react'
KDReactorMixin = require 'app/flux/reactormixin'
ActivityFlux   = require 'activity/flux'
immutable      = require 'immutable'
classnames     = require 'classnames'
ThreadSidebar  = require 'activity/components/threadsidebar'
ThreadHeader   = require 'activity/components/threadheader'

module.exports = class ChannelThreadPane extends React.Component

  { getters } = ActivityFlux

  getDataBindings: ->
    return {
      channelThread         : getters.selectedChannelThread
      channelThreadMessages : getters.selectedChannelThreadMessages
      messageThread         : getters.selectedMessageThread
      messageThreadComments : getters.selectedMessageThreadComments
      popularMessages       : getters.selectedChannelPopularMessages
      channelParticipants   : getters.selectedChannelParticipants
    }


  constructor: (props) ->

    super props

    @state =
      channelThread         : immutable.Map()
      channelThreadMessages : immutable.List()
      messageThread         : immutable.Map()
      messageThreadComments : immutable.List()
      popularMessages       : immutable.List()
      channelParticipants   : immutable.List()


  componentDidMount: -> reset @props


  componentWillReceiveProps: (nextProps) -> reset nextProps


  renderHeader: ->
    <ThreadHeader
      channelThread={@state.channelThread}
      messageThread={@state.messageThread}
      isSummaryActive={!!@props.feed}
    />


  renderFeed: ->
    return null  unless @props.feed

    React.cloneElement @props.feed,
      thread   : @state.channelThread
      messages : @state.popularMessages


  renderChat: ->
    return null  unless @props.chat

    React.cloneElement @props.chat,
      thread   : @state.channelThread
      messages : @state.channelThreadMessages


  renderPost: ->

    return null  unless @props.post

    React.cloneElement @props.post,
      thread        : @state.messageThread
      messages      : @state.messageThreadComments
      channelThread : @state.channelThread


  renderSidebar: ->
    <ThreadSidebar
      channelThread={@state.channelThread}
      popularMessages={@state.popularMessages}
      channelParticipants={@state.channelParticipants}/>


  getClassName: ->

    classnames(
      ChannelThreadPane: yes
      'is-withFeed': @props.feed
      'is-withChat': @props.chat
      'is-withPost': @props.post
    )


  render: ->
    <div className={@getClassName()}>
      <section className="ChannelThreadPane-content">
        <header className="ChannelThreadPane-header">
          {@renderHeader()}
        </header>
        <div className="ChannelThreadPane-body">
          <section className="ChannelThreadPane-feedWrapper">
            {@renderFeed()}
          </section>
          <section className="ChannelThreadPane-chatWrapper">
            {@renderChat()}
          </section>
          <section className="ChannelThreadPane-postWrapper">
            {@renderPost()}
          </section>
        </div>
      </section>
      <aside className="ChannelThreadPane-sidebar">
        {@renderSidebar()}
      </aside>
    </div>


React.Component.include.call ChannelThreadPane, [KDReactorMixin]

reset = (props) ->

  { channelName, postSlug } = props.params
  { thread, channel: channelActions, message: messageActions } = ActivityFlux.actions

  if channelName
    channelActions.loadChannelByName(channelName).then ({ channel }) ->
      thread.changeSelectedThread channel.id
      channelActions.loadPopularMessages channel.id
      channelActions.loadParticipants channel.id, channel.participantsPreview

  else
    thread.changeSelectedThread null

  if postSlug
    messageActions.loadMessageBySlug(postSlug).then ({ message }) ->
      messageActions.changeSelectedMessage message.id
  else
    messageActions.changeSelectedMessage null


