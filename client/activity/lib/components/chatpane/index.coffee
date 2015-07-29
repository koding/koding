kd = require 'kd'
React = require 'kd-react'
ChatInputWidget = require 'activity/components/chatinputwidget'
ChatList = require 'activity/components/chatlist'


module.exports = class ChatPane extends React.Component

  @defaultProps =
    title    : null
    messages : null


  componentDidUpdate: ->

    list = React.findDOMNode(@refs.ChatList)
    body = React.findDOMNode(@refs.ChatPaneBody)

    return  unless list and body

    list       = list.firstElementChild
    listHeight = list.offsetHeight
    bodyHeight = body.offsetHeight

    if (listHeight > bodyHeight)
    then list.classList.remove 'padded'
    else list.classList.add 'padded'


  onSubmit: (event) -> @props.onSubmit? event


  renderHeader: ->
    return null  unless @props.title

    <header className="ChatPane-header">
      <h3 className="ChatPane-NameLabel">{@props.title}</h3>
      <div className="ChatPane-SettingsMenuButton"></div>
      <div className="ChatPane-SearchWidget"></div>
    </header>


  renderBody: ->
    return null  unless @props.messages

    messages = @props.messages.sortBy (m) -> m?.get 'createdAt'

    <section className="ChatPane-body" ref="ChatPaneBody">
      <div className="ChatList" ref="ChatList">
        <ChatList messages={messages}/>
      </div>
    </section>


  renderFooter: ->

    <footer className="ChatPane-footer">
      <ChatInputWidget onSubmit={@bound 'onSubmit'} />
    </footer>


  render: ->
    <div className={kd.utils.curry 'ChatPane', @props.className}>
      <section className="ChatPane-contentWrapper">
        {@renderHeader()}
        {@renderBody()}
        {@renderFooter()}
      </section>
    </div>


