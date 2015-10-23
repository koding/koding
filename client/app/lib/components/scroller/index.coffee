kd = require 'kd'
React = require 'kd-react'
Waypoint = require 'react-waypoint'

module.exports = class Scroller extends React.Component

  @defaultProps =
    hasMore               : no
    threshold             : 1
    onThresholdReached    : kd.noop
    onTopThresholdReached : kd.noop
    className             : ''


  renderTopWaypoint: ->

    <Waypoint onEnter={@props.onTopThresholdReached} threshold={@props.threshold} />


  renderBottomWaypoint: ->

    <Waypoint onEnter={@props.onThresholdReached} threshold={@props.threshold} />


  render: ->

    <div className={kd.utils.curry 'Scrollable', @props.className} ref="scrollContainer">
      {@renderTopWaypoint()}
      {@props.children}
      {@renderBottomWaypoint()}
    </div>


