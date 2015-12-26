kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
FeedList             = require './feedlist'
Scroller             = require 'app/components/scroller'
Encoder              = require 'htmlencode'
whoami               = require 'app/util/whoami'
immutable            = require 'immutable'
FeedInputWidget      = require './feedinputwidget'
FeedPaneTabContainer = require './feedpanetabcontainer'
FeedThreadHeader     = require './feedthreadheader'
FeedThreadSidebar    = require 'activity/components/publicfeedpane/feedthreadsidebar'

module.exports = class FeedPane extends React.Component

  @defaultProps =
    title           : null
    messages        : null
    isDataLoading   : no
    onInviteOthers  : kd.noop
    showItemMenu    : yes
    popularChannels : immutable.List()


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

    channelId = @props.thread.get 'channelId'

    <Scroller
      style={{height: 'auto'}}
      ref='scrollContainer'
      hasMore={@props.thread.get('messages').size}
      onThresholdReached={@bound 'onThresholdReached'}>
      <aside className='FeedThreadPane-sidebar'>
        <FeedThreadSidebar
          popularChannels={@props.popularChannels} />
      </aside>
      <FeedThreadHeader
        className="FeedThreadPane-header"
        thread={@props.thread} />
      <FeedInputWidget channelId={channelId} />
      <FeedPaneTabContainer thread={@props.thread} />
      <FeedList
        channelId={channelId}
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


