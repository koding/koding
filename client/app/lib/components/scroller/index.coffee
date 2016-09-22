kd = require 'kd'
React = require 'app/react'

PerfectScrollbar = require 'app/components/perfectscrollbar'

require './styl/scrollable.styl'

module.exports = class Scroller extends React.Component

  @defaultProps =
    hasMore               : no
    onScroll              : kd.noop
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


  _update: -> @refs.scrollContainer._update()


  render: ->

    <PerfectScrollbar
      {...@props}
      onScroll={@props.onScroll}
      className={kd.utils.curry 'Scrollable', @props.className}
      onUpLimitReached={@bound 'onUpLimitReached'}
      onDownLimitReached={@bound 'onDownLimitReached'}
      ref='scrollContainer'>
      {@props.children}
    </PerfectScrollbar>
