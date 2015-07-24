kd              = require 'kd'
React           = require 'kd-react'
immutable       = require 'immutable'
ChatInputWidget = require 'activity/components/chatinputwidget'
ActivityFlux    = require 'activity/flux'
KDReactorMixin  = require 'app/flux/reactormixin'
ChatList        = require 'activity/components/chatlist'


module.exports = class PublicChatPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()
    padded   : no


  componentDidMount: ->

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

    if (chatListHeight > publicChatPaneBodyHeight)
    then chatList.classList.remove 'padded'
    else chatList.classList.add 'padded'


  channel: (key) -> @props.thread.getIn ['channel', key]


  onSubmit: ({ value }) ->

    body = value
    name = @channel 'name'

    unless body.match ///\##{name}///
      body += " ##{name} "

    ActivityFlux.actions.message.createMessage @channel('id'), body


  render: ->
    messages = @props.messages.sortBy (m) -> m?.get 'createdAt'
    <div className="PublicChatPane">
      <section className="PublicChatPane-contentWrapper">
        <header className="PublicChatPane-header">
          <h3 className="PublicChatPane-NameLabel">{@channel 'name'}</h3>
          <div className="PublicChatPane-SettingsMenuButton"></div>
          <div className="PublicChatPane-SearchWidget"></div>
        </header>
        <section className="PublicChatPane-body" ref="PublicChatPaneBody">
          <div className="PublicChatList" ref="PublicChatList">
            <ChatList messages={messages}/>
          </div>
        </section>
        <footer className="PublicChatPane-footer">
          <ChatInputWidget onSubmit={@bound 'onSubmit'} />
        </footer>
      </section>
    </div>


