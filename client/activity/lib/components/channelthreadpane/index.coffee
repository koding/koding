kd             = require 'kd'
React          = require 'kd-react'
KDReactorMixin = require 'app/flux/reactormixin'
ActivityFlux   = require 'activity/flux'
immutable      = require 'immutable'
classnames     = require 'classnames'

module.exports = class ChannelThreadPane extends React.Component

  { getters } = ActivityFlux

  getDataBindings: ->
    return {
      channelThread         : getters.selectedChannelThread
      channelThreadMessages : getters.selectedChannelThreadMessages
      messageThread         : getters.selectedMessageThread
      messageThreadComments : getters.selectedMessageThreadComments
      popularMessages       : getters.selectedChannelPopularMessages
    }


  constructor: (props) ->

    super props

    @state =
      channelThread         : immutable.Map()
      channelThreadMessages : immutable.List()
      messageThread         : immutable.Map()
      messageThreadComments : immutable.List()
      popularMessages       : immutable.List()


  componentDidMount: -> reset @props


  componentWillReceiveProps: (nextProps) -> reset nextProps


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


  renderChannelSidebar: -> null


  getClassName: ->

    classnames(
      ChannelThreadPane: yes
      'is-withFeed': @props.feed
      'is-withChat': @props.chat
      'is-withPost': @props.post
    )


  render: ->
    <div className={@getClassName()}>
      <section className="ChannelThreadPane-feedWrapper">
        {@renderFeed()}
      </section>
      <section className="ChannelThreadPane-chatWrapper">
        {@renderChat()}
      </section>
      <section className="ChannelThreadPane-postWrapper">
        {@renderPost()}
      </section>
      {@renderChannelSidebar()}
    </div>


React.Component.include.call ChannelThreadPane, [KDReactorMixin]

reset = (props) ->

  { channelName, postSlug } = props.params
  { thread, channel: channelActions, message: messageActions } = ActivityFlux.actions

  if channelName
    channelActions.loadChannelByName(channelName).then ({ channel }) ->
      thread.changeSelectedThread channel.id
      channelActions.loadPopularMessages channel.id

  if postSlug
    messageActions.loadMessageBySlug(postSlug).then ({ message }) ->
      messageActions.changeSelectedMessage message.id


