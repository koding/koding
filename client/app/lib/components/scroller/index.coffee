kd = require 'kd'
React = require 'kd-react'
Waypoint = require 'react-waypoint'

PerfectScrollbar = require 'app/components/perfectscrollbar'

module.exports = class Scroller extends React.Component

  @defaultProps =
    hasMore               : no
    threshold             : 1
    onThresholdReached    : kd.noop
    onTopThresholdReached : kd.noop
    minScrollbarLength    : 64
    useSelectionScroll    : on

  renderTopWaypoint: ->

    return null  unless @props.hasMore

    <Waypoint onEnter={@props.onTopThresholdReached} threshold={@props.threshold} />


  renderBottomWaypoint: ->

    return null  unless @props.hasMore

    <Waypoint onEnter={@props.onThresholdReached} threshold={@props.threshold} />


  render: ->

    <PerfectScrollbar
      {...@props}
      className={kd.utils.curry 'Scrollable', @props.className}
      ref='scrollContainer'>
      {@renderTopWaypoint()}
      {@props.children}
      {@renderBottomWaypoint()}
    </PerfectScrollbar>


