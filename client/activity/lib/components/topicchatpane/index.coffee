kd    = require 'kd'
React = require 'kd-react'
immutable = require 'immutable'

ChatInputWidget      = require 'activity/components/chatinputwidget'
ActivityFlux         = require 'activity/flux'
KDReactorMixin       = require 'app/flux/reactormixin'

ChatList = require 'activity/components/chatlist'

module.exports = class TopicChatPane extends React.Component

  constructor: (props) ->

    super props

    @state = { channel: @props.channel or null, messages: immutable.List() }


  getDataBindings: ->
    return {
      messages: ActivityFlux.getters.selectedChannelThreadMessages
    }


  componentDidMount: ->

    { thread, message } = ActivityFlux.actions

    thread.changeSelectedThread @state.channel.id
    message.loadMessages @state.channel.id


  channel: (key) -> if key then @state.channel[key] else @state.channel

  onSubmit: ({ value }) ->

    body = value
    name = @channel 'name'

    unless body.match ///\##{name}///
      body += " ##{name} "

    ActivityFlux.actions.message.createMessage @channel('id'), body


  render: ->
    messages = @state.messages.sortBy (m) -> m.get 'createdAt'
    <div className="TopicChatPane">
      <section className="TopicChatPane-contentWrapper">
        <header className="TopicChatPane-header">
          <div className="u-h4 TopicChatPane-NameLabel">{@channel 'name'}</div>
          <div className="TopicChatPane-SettingsMenuButton"></div>
          <div className="TopicChatPane-SearchWidget"></div>
        </header>
        <section className="TopicChatPane-body">
          <div className="TopicChatList">
            <ChatList messages={messages} />
          </div>
        </section>
        <footer className="TopicChatPane-footer">
          <ChatInputWidget onSubmit={@bound 'onSubmit'} />
        </footer>
      </section>
    </div>


React.Component.include.call TopicChatPane, [KDReactorMixin]
