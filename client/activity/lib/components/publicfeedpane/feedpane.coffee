kd                   = require 'kd'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
FeedList             = require './feedlist'
Scroller             = require 'app/components/scroller'
immutable            = require 'immutable'
FeedInputWidget      = require './feedinputwidget'
FeedPaneTabContainer = require './feedpanetabcontainer'
FeedThreadHeader     = require './feedthreadheader'
FeedThreadSidebar    = require 'activity/components/publicfeedpane/feedthreadsidebar'
ActivityFlux         = require 'activity/flux'
KDReactorMixin       = require 'app/flux/base/reactormixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'
ActivitySharePopup   = require 'activity/components/activitysharepopup'
groupifyLink         = require 'app/util/groupifyLink'

module.exports = class FeedPane extends React.Component

  @defaultProps =
    popularChannels : immutable.List()
    messages : null


  getDataBindings: ->
    return {
      socialShareLinks        : ActivityFlux.getters.socialShareLinks
      activeSocialShareLinkId : ActivityFlux.getters.activeSocialShareLinkId
    }


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


  unsetActiveSocialShareLink: kd.utils.debounce 400, ->

    @setState isOpened: yes
    ActivityFlux.actions.feed.setActiveSocialShareLink null


  onScroll: ->

    @setState isOpened: no
    @unsetActiveSocialShareLink()


  renderSocialSharePopup: ->

    { socialShareLinks, activeSocialShareLinkId } = @state

    return null  unless activeSocialShareLinkId

    message  = @props.thread.getIn ['messages', activeSocialShareLinkId]
    shareUrl = groupifyLink "Activity/Post/#{message.get('slug')}", yes
    socialShareLinkComponent = socialShareLinks.get activeSocialShareLinkId

    <ActivitySharePopup
      ref='ActivitySharePopup'
      socialShareLinkComponent={socialShareLinkComponent}
      message={message}
      url = shareUrl
      className='FeedItem-sharePopup'
      isOpened={@state.isOpened} />


  renderBody: ->

    return null  unless @props.thread

    channelId = @props.thread.get 'channelId'

    <Scroller
      onScroll={@bound 'onScroll'}
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
          {@renderSocialSharePopup()}
        </section>
      </section>
    </div>


React.Component.include.call FeedPane, [
  KDReactorMixin, ImmutableRenderMixin
]


_hideScroller = (scroller) -> scroller?.style.opacity = 0

_showScroller = (scroller) -> scroller?.style.opacity = 1


