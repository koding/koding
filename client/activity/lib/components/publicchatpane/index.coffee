kd    = require 'kd'
React = require 'kd-react'
immutable = require 'immutable'

ChatInputWidget      = require 'activity/components/chatinputwidget'
ActivityFlux         = require 'activity/flux'
KDReactorMixin       = require 'app/flux/reactormixin'

ChatList = require 'activity/components/chatlist'

module.exports = class PublicChatPane extends React.Component

  constructor: (props) ->

    super props

    @state = { channel: @props.channel or null, messages: immutable.List(), padded: no }


  getDataBindings: ->
    return {
      messages: ActivityFlux.getters.selectedChannelThreadMessages
    }


  componentDidMount: ->

    { thread, message } = ActivityFlux.actions
    thread.changeSelectedThread @state.channel.id
    message.loadMessages @state.channel.id
    @createModalContainer()


  createModalContainer: ->
    ModalContainer = document.createElement 'div'
    ModalContainer.setAttribute 'class', 'PublicChatPane-ModalContainer hidden'
    document.body.appendChild ModalContainer


  componentDidUpdate: ->
    PublicChatList           = React.findDOMNode(@refs.PublicChatList)
    PublicChatPaneBody       = React.findDOMNode(@refs.PublicChatPaneBody)
    chatList                 = PublicChatList.firstElementChild
    chatListHeight           = chatList.offsetHeight
    publicChatPaneBodyHeight = PublicChatPaneBody.offsetHeight

    if (chatListHeight > publicChatPaneBodyHeight) then chatList.classList.remove "padded" else chatList.classList.add "padded"


  channel: (key) -> if key then @state.channel[key] else @state.channel


  onSubmit: ({ value }) ->

    body = value
    name = @channel 'name'

    unless body.match ///\##{name}///
      body += " ##{name} "

    ActivityFlux.actions.message.createMessage @channel('id'), body


  render: ->
    messages = @state.messages.sortBy (m) -> m?.get 'createdAt'
    chatListClassName = if @state.padded then 'padded' else ''
    <div className="PublicChatPane">
      <section className="PublicChatPane-contentWrapper">
        <header className="PublicChatPane-header">
          <h1 className="u-h4 PublicChatPane-NameLabel">{@channel 'name'}</h1>
          <div className="PublicChatPane-SettingsMenuButton"></div>
          <div className="PublicChatPane-SearchWidget"></div>
        </header>
        <section className="PublicChatPane-body" ref="PublicChatPaneBody">
          <div className="PublicChatList" ref="PublicChatList">
            <ChatList className={chatListClassName} messages={messages}/>
          </div>
        </section>
        <footer className="PublicChatPane-footer">
          <ChatInputWidget onSubmit={@bound 'onSubmit'} />
        </footer>
      </section>
    </div>


React.Component.include.call PublicChatPane, [KDReactorMixin]
