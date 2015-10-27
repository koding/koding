kd = require 'kd'
React = require 'kd-react'
Waypoint = require 'react-waypoint'

module.exports = class Scroller extends React.Component

  @defaultProps =
    hasMore               : no
    threshold             : 1
    onThresholdReached    : kd.noop
    onTopThresholdReached : kd.noop


  renderTopWaypoint: ->

    <Waypoint onEnter={@props.onTopThresholdReached} threshold={@props.threshold} />


  renderBottomWaypoint: ->

    <Waypoint onEnter={@props.onThresholdReached} threshold={@props.threshold} />


  render: ->

    <div className='Scrollable' ref='scrollContainer'>
      {@renderTopWaypoint()}
      {@props.children}
      {@renderBottomWaypoint()}
    </div>


