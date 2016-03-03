kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
FeedList             = require '../feedlist'
Scroller             = require 'app/components/scroller'
immutable            = require 'immutable'
checkFlag            = require 'app/util/checkFlag'
FeedInputWidget      = require '../feedinputwidget'
FeedPaneTabContainer = require './tabcontainer'
FeedThreadHeader     = require '../feedthreadheader'
FeedThreadSidebar    = require 'activity/components/publicfeedpane/feedthreadsidebar'
ActivitySharePopup   = require 'activity/components/activitysharepopup'
groupifyLink         = require 'app/util/groupifyLink'


module.exports = class FeedPane extends React.Component

  @propTypes =
    key                     : React.PropTypes.string
    thread                  : React.PropTypes.instanceOf immutable.Map
    isOpened                : React.PropTypes.bool
    onScroll                : React.PropTypes.func
    onLoadMore              : React.PropTypes.func
    popularChannels         : React.PropTypes.instanceOf immutable.Map
    socialShareLinks        : React.PropTypes.instanceOf immutable.Map
    onThresholdReached      : React.PropTypes.func
    showPopularMessages     : React.PropTypes.func
    showMostRecentMessages  : React.PropTypes.func
    activeSocialShareLinkId : React.PropTypes.string


  @defaultProps =
    key                     : ''
    thread                  : immutable.Map()
    isOpened                : no
    onScroll                : kd.noop
    onLoadMore              : kd.noop
    popularChannels         : immutable.Map()
    socialShareLinks        : immutable.Map()
    onThresholdReached      : kd.noop
    showPopularMessages     : kd.noop
    showMostRecentMessages  : kd.noop
    activeSocialShareLinkId : ''

  getMessages: ->

    messages = @props.thread.get 'messages'

    return immutable.Map()  unless messages

    messages.sort (a, b) ->
      if a.get('createdAt') > b.get('createdAt') then -1
      else if a.get('createdAt') < b.get('createdAt') then return 1
      else 0


  renderSocialSharePopup: ->

    { socialShareLinks, activeSocialShareLinkId } = @props

    return null  unless activeSocialShareLinkId

    message  = @props.thread.getIn ['messages', activeSocialShareLinkId]
    shareUrl = groupifyLink "Activity/Post/#{message.get('slug')}", yes
    socialShareLinkComponent = socialShareLinks.get activeSocialShareLinkId

    <ActivitySharePopup
      ref                      = 'ActivitySharePopup'
      url                      = shareUrl
      message                  = { message }
      isOpened                 = { @props.isOpened }
      className                = 'FeedItem-sharePopup'
      socialShareLinkComponent = { socialShareLinkComponent } />


  renderFeedInputWidgetAndTabContainer: (channelId, thread, isAnnouncementChannel) ->

    return null  if not checkFlag('super-admin') and isAnnouncementChannel

    <div>
      <FeedInputWidget channelId = { channelId } />
      <FeedPaneTabContainer
        thread                 = { thread }
        showPopularMessages    = { @props.showPopularMessages }
        showMostRecentMessages = { @props.showMostRecentMessages }/>
    </div>


  renderBody: ->

    return null  unless @props.thread

    channelId    = @props.thread.get 'channelId'
    typeConstant = @props.thread.getIn(['channel', 'typeConstant'])

    isAnnouncementChannel = typeConstant is 'announcement'

    <Scroller
      ref                = 'scrollContainer'
      style              = { {height: 'auto'} }
      hasMore            = { @props.thread.get('messages').size }
      onScroll           = { @props.onScroll }
      onThresholdReached = { @props.onThresholdReached }>
      <aside className='FeedThreadPane-sidebar'>
        <FeedThreadSidebar
          popularChannels = { @props.popularChannels } />
      </aside>
      <FeedThreadHeader.Container
        channel   = { @props.thread.get 'channel' }
        className = "FeedThreadPane-header" />
      { @renderFeedInputWidgetAndTabContainer channelId, @props.thread, isAnnouncementChannel }

      <FeedList
        messages          = { @getMessages() }
        channelId         = { channelId }
        isMessagesLoading = { @isThresholdReached } />
    </Scroller>


  render: ->

    <div className = { kd.utils.curry 'FeedPane', @props.className }>
      <section className = "Pane-contentWrapper">
        <section className = "Pane-body">
          {@renderBody()}
          {@props.children}
          {@renderSocialSharePopup()}
        </section>
      </section>
    </div>