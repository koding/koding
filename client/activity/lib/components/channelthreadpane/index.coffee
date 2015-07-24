kd             = require 'kd'
React          = require 'kd-react'
KDReactorMixin = require 'app/flux/reactormixin'
ActivityFlux   = require 'activity/flux'
immutable      = require 'immutable'
classnames     = require 'classnames'

module.exports = class ChannelThreadPane extends React.Component

  getDataBindings: ->
    return {
      messages : ActivityFlux.getters.selectedChannelThreadMessages
      thread   : ActivityFlux.getters.selectedChannelThread
    }


  constructor: (props) ->

    super props

    @state = { thread: immutable.Map(), messages: immutable.List() }


  componentDidMount: ->

    { thread, channel } = ActivityFlux.actions

    thread.changeSelectedThreadByName @props.params.slug
    channel.loadChannelByName @props.params.slug


  renderWithState: (component) ->

    React.cloneElement component,
      thread   : @state.thread
      messages : @state.messages


  renderFeed: ->
    return null  unless @props.feed

    @renderWithState @props.feed


  renderChat: ->
    return null  unless @props.chat

    @renderWithState @props.chat


  renderChannelSidebar: -> null


  getClassName: ->

    classnames(
      ChannelThreadPane: yes
      'is-withFeed': @props.feed
      'is-withChat': @props.chat
    )


  render: ->
    <div className={@getClassName()}>
      <section className="ChannelThreadPane-feedWrapper">
        {@renderFeed()}
      </section>
      <section className="ChannelThreadPane-chatWrapper">
        {@renderChat()}
      </section>
      {@renderChannelSidebar()}
    </div>


React.Component.include.call ChannelThreadPane, [KDReactorMixin]

