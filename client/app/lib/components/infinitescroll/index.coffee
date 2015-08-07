kd                       = require 'kd'
$                        = require 'jquery'
React                    = require 'kd-react'
isScrollThresholdReached = require 'app/util/isScrollThresholdReached'

module.exports = class InfiniteScroll extends React.Component

  @defaultProps =
    isDataLoading   : no
    scrollDirection : 'up'
    scrollOffset    : 200


  onScroll: (event) ->
    isScrollLoadable = isScrollThresholdReached
      el              : event.target
      isDataLoading   : @props.isDataLoading
      scrollDirection : @props.scrollDirection
      scrollOffset    : @props.scrollOffset


    @props.onScrollThresholdReached() if isScrollLoadable


  render: ->
    <div className="InfiniteScroll" onScroll={ @bound 'onScroll' }>
      {@props.children}
    </div>

