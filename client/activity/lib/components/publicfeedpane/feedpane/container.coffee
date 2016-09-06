kd                   = require 'kd'
View                 = require './view'
React                = require 'kd-react'
ReactDOM             = require 'react-dom'
immutable            = require 'immutable'
ActivityFlux         = require 'activity/flux'
KDReactorMixin       = require 'app/flux/base/reactormixin'
ImmutableRenderMixin = require 'react-immutable-render-mixin'


module.exports = class FeedPaneContainer extends React.Component

  @propTypes =
    key             : React.PropTypes.string
    thread          : React.PropTypes.instanceOf immutable.Map
    messages        : React.PropTypes.instanceOf immutable.Map
    onLoadMore      : React.PropTypes.func
    popularChannels : React.PropTypes.instanceOf immutable.Map

  @defaultProps =
    key             : ''
    thread          : null
    messages        : null
    onLoadMore      : kd.noop
    popularChannels : immutable.Map()


  getDataBindings: ->

    return {
      socialShareLinks        : ActivityFlux.getters.socialShareLinks
      activeSocialShareLinkId : ActivityFlux.getters.activeSocialShareLinkId
    }


  componentDidMount: ->

    scroller = ReactDOM.findDOMNode @refs.view.refs.scrollContainer
    _showScroller scroller


  unsetActiveSocialShareLink: kd.utils.debounce 400, ->

    @setState isOpened: yes
    ActivityFlux.actions.feed.setActiveSocialShareLink null


  onThresholdReached: (event) ->

    messages = @props.thread.get 'messages'

    return  if @isThresholdReached

    return  unless messages.size

    @isThresholdReached = yes

    kd.utils.wait 500, => @props.onLoadMore()


  onScroll: ->

    @setState isOpened: no
    @unsetActiveSocialShareLink()

  showPopularMessages: (event) ->

    kd.utils.stopDOMEvent event

    @handleRoute 'Liked'


  showMostRecentMessages: (event) ->

    kd.utils.stopDOMEvent event

    @handleRoute '/Recent'


  handleRoute: (route) ->

    channelName = @props.thread.getIn ['channel', 'name']
    route       = "/Channels/#{channelName}/#{route}"

    kd.singletons.router.handleRoute route


  render: ->

    <View
      ref                     = 'view'
      key                     = { @props.key }
      thread                  = { @props.thread }
      isOpened                = { @state.isOpened }
      messages                = { @props.messages }
      onScroll                = { @bound 'onScroll' }
      onLoadMore              = { @props.onLoadMore }
      popularChannels         = { @propspopularChannels }
      socialShareLinks        = { @state.socialShareLinks }
      onThresholdReached      = { @bound 'onThresholdReached' }
      showPopularMessages     = { @bound 'showPopularMessages' }
      showMostRecentMessages  = { @bound 'showMostRecentMessages' }
      activeSocialShareLinkId = { @state.activeSocialShareLinkId }/>

React.Component.include.call FeedPaneContainer, [
  KDReactorMixin, ImmutableRenderMixin
]


_hideScroller = (scroller) -> scroller?.style.opacity = 0

_showScroller = (scroller) -> scroller?.style.opacity = 1
