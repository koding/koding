kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
FeedList             = require 'activity/components/feedlist'
ActivityFlux         = require 'activity/flux'
Scroller             = require 'app/components/scroller'
FeedThreadHeader     = require 'activity/components/feedthreadheader'
Encoder              = require 'htmlencode'
whoami               = require 'app/util/whoami'
Button               = require 'app/components/common/button'
Link                 = require 'app/components/common/link'
generateDummyMessage = require 'app/util/generateDummyMessage'
ProfileLinkContainer = require 'app/components/profile/profilelinkcontainer'
ProfileText          = require 'app/components/profile/profiletext'
Avatar               = require 'app/components/profile/avatar'
TimeAgo              = require 'app/components/common/timeago'
toImmutable          = require 'app/util/toImmutable'
AutoSizeTextarea     = require 'app/components/common/autosizetextarea'
MessageBody          = require 'activity/components/common/messagebody'

module.exports = class FeedPane extends React.Component

  @defaultProps =
    title          : null
    messages       : null
    isDataLoading  : no
    onInviteOthers : kd.noop
    showItemMenu   : yes

  constructor: (props) ->

    super props

    @state =
      previewMode: no
      value: ''

  flag: (key) -> @props.thread?.getIn ['flags', key]

  channel: (key) -> @props.thread?.getIn ['channel', key]

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


  onChange: (event) -> @setState value: event.target.value


  onSubmit: (event) ->

    kd.utils.stopDOMEvent event

    value = @state.value.trim()

    return  unless value

    ActivityFlux.actions.message.createMessage @channel('id'), value
      .then =>
        @setState { value: '', previewMode: no }


  onResize: ->


  toggleMarkdownPreviewMode: (event) ->

    @setState previewMode: not @state.previewMode


  renderFeedInputWidget: ->

    firstName   = Encoder.htmlDecode(whoami().profile.firstName)
    placeholder = "Hey #{firstName}, share something interesting or ask a question."

    <header className="PublicFeedPane-header FeedPaneHeader">
      <i></i>
      <AutoSizeTextarea
        placeholder={placeholder}
        value={@state.value}
        onChange={@bound 'onChange'}
        onResize={ @bound 'onResize' }
        />
      <div className='FeedPaneHeader-buttonBar'>
        <Button
          tabIndex={1}
          className='FeedPaneHeader-preview'
          onClick={ @bound 'toggleMarkdownPreviewMode' } />
        <Button
          tabIndex={0}
          className='FeedPaneHeader-send'
          onClick={ @bound 'onSubmit' }>SEND</Button>
      </div>
    </header>


  renderHeader: ->

    <FeedThreadHeader
      className="FeedThreadPane-header"
      thread={@props.thread}>
    </FeedThreadHeader>


  renderPreviewMode: ->

    return null  unless @state.previewMode

    message = toImmutable generateDummyMessage @state.value
    message = message.set 'isPreview', yes

    <div className='FeedPane-previewWrapper MediaObject'>
      <Link
        onClick={@bound 'toggleMarkdownPreviewMode'}
        className='FeedPreviewItem-closePreview'>
        Previewing
      </Link>
      <div className='MediaObject-media'>
        <ProfileLinkContainer origin={message.get('account').toJS()}>
          <Avatar className="FeedItem-Avatar" width={35} height={35} />
        </ProfileLinkContainer>
      </div>
      <ProfileLinkContainer key={message.getIn(['account', 'id'])} origin={message.get('account').toJS()}>
        <ProfileText />
      </ProfileLinkContainer>
      <div className='FeedPreviewItem-date'>
        <TimeAgo from={message.get 'createdAt'} className='FeedItem-date'/>
      </div>
      <div className='FeedPreviewItem-body'>
        <MessageBody message={message}/>
      </div>
    </div>


  renderTabs: ->

    return null  unless @props.thread

    <div className='FeedList-tabContainer'>
      <Link className='FeedList-tab'>Most Liked</Link>
      <Link className='FeedList-tab active'>Most Recent</Link>
      <div>
        <input className='FeedList-searchInput' placeholder='Search...'/>
        <i className='FeedList-searchIcon'/>
      </div>
    </div>


  renderBody: ->

    return null  unless @props.thread

    <Scroller
      style={{height: 'auto'}}
      ref='scrollContainer'
      hasMore={@props.thread.get('messages').size}
      onThresholdReached={@bound 'onThresholdReached'}>
      {@renderHeader()}
      {@renderFeedInputWidget()}
      {@renderPreviewMode()}
      {@renderTabs()}
      <FeedList
        ref='FeedList'
        isMessagesLoading={@isThresholdReached}
        messages={@getMessages()}
      />
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


