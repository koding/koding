kd                       = require 'kd'
$                        = require 'jquery'
React                    = require 'kd-react'
isScrollThresholdReached = require 'app/util/isScrollThresholdReached'

module.exports = class InfiniteScroll extends React.Component

  @defaultProps =
    isDataLoading   : no
    scrollDirection : 'up'
    scrollOffset    : 200
    isScrollBottom  : yes
    scrollMoveTo    : 'up'


  isInitialLoadComplete: no


  onWheel: (event) ->

    @scrollMoveTo = 'up'   if event.deltaY < 0
    @scrollMoveTo = 'down' if event.deltaY > 0


  onScroll: (event) ->

    isScrollLoadable = isScrollThresholdReached
      el              : event.target
      scrollMoveTo    : @scrollMoveTo
      isDataLoading   : @props.isDataLoading
      scrollDirection : @props.scrollDirection
      scrollOffset    : @props.scrollOffset


    @props.onScrollThresholdReached() if isScrollLoadable


  componentWillUpdate: ->

    InfiniteScroll = React.findDOMNode(@refs.InfiniteScroll)
    @scrollTop     = InfiniteScroll.scrollTop
    @offsetHeight  = InfiniteScroll.offsetHeight
    @scrollHeight  = InfiniteScroll.scrollHeight
    @shouldScrollBottom = (@scrollTop + InfiniteScroll.offsetHeight) is @scrollHeight


  componentDidUpdate: ->

    if @shouldScrollBottom
      InfiniteScroll = React.findDOMNode(@refs.InfiniteScroll)
      InfiniteScroll.scrollTop = InfiniteScroll.scrollHeight
    else
      InfiniteScroll.scrollTop = @scrollTop + (InfiniteScroll.scrollHeight - @scrollHeight)

    if not @props.isDataLoading and not @isInitialLoadComplete and @offsetHeight
      InfiniteScroll.scrollTop = InfiniteScroll.scrollHeight
      @isInitialLoadComplete = yes


  render: ->
    <div className="InfiniteScroll" ref="InfiniteScroll" onScroll={ @bound 'onScroll' } onWheel={ @bound 'onWheel'}>
      {@props.children}
    </div>

