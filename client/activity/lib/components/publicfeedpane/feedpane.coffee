kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
FeedList             = require './feedlist'
Scroller             = require 'app/components/scroller'
FeedThreadHeader     = require './feedthreadheader'
Encoder              = require 'htmlencode'
whoami               = require 'app/util/whoami'
FeedPaneTabContainer = require './feedpanetabcontainer'
FeedInputWidget      = require './feedinputwidget'

module.exports = class FeedPane extends React.Component

  @defaultProps =
    title          : null
    messages       : null
    isDataLoading  : no
    onInviteOthers : kd.noop
    showItemMenu   : yes


  componentDidMount: ->

    scroller = ReactDOM.findDOMNode @refs.scrollContainer
    _showScroller scroller


  onThresholdReached: (event) ->

    messages = @props.thread.get 'messages'

    return  if @isThresholdReached

    return  unless messages.size

    @isThresholdReached = yes

    kd.utils.wait 500, => @props.onLoadMore()


  getMessages: ->

    messages = @props.thread.get 'messages'

    return immutable.Map()  unless messages

    messages.sort (a, b) ->
      if a.get('createdAt') > b.get('createdAt') then -1
      else if a.get('createdAt') < b.get('createdAt') then return 1
      else 0


  renderBody: ->

    return null  unless @props.thread

    <Scroller
      style={{height: 'auto'}}
      ref='scrollContainer'
      hasMore={@props.thread.get('messages').size}
      onThresholdReached={@bound 'onThresholdReached'}>
      <FeedThreadHeader
        className="FeedThreadPane-header"
        thread={@props.thread} />
      <FeedInputWidget thread={@props.thread} />
      <FeedPaneTabContainer thread={@props.thread} />
      <FeedList
        isMessagesLoading={@isThresholdReached}
        messages={@getMessages()} />
    </Scroller>


  render: ->
    <div className={kd.utils.curry 'FeedPane', @props.className}>
      <section className="Pane-contentWrapper">
        <section className="Pane-body">
          {@renderBody()}
          {@props.children}
        </section>
      </section>
    </div>


_hideScroller = (scroller) -> scroller?.style.opacity = 0

_showScroller = (scroller) -> scroller?.style.opacity = 1


