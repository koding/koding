kd = require 'kd'
React = require 'kd-react'

PerfectScrollbar = require 'app/components/perfectscrollbar'

module.exports = class Scroller extends React.Component

  @defaultProps =
    hasMore               : no
    threshold             : 1
    onThresholdReached    : kd.noop
    onTopThresholdReached : kd.noop
    minScrollbarLength    : 64
    useSelectionScroll    : on

  onUpLimitReached: ->

    return  unless @props.hasMore

    @props.onTopThresholdReached?()


  onDownLimitReached: ->

    return  unless @props.hasMore

    @props.onThresholdReached?()


  render: ->

    <PerfectScrollbar
      {...@props}
      className={kd.utils.curry 'Scrollable', @props.className}
      onUpLimitReached={@bound 'onUpLimitReached'}
      onDownLimitReached={@bound 'onDownLimitReached'}
      ref='scrollContainer'>
      {@props.children}
    </PerfectScrollbar>


