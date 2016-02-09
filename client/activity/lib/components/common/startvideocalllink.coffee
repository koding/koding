kd    = require 'kd'
React = require 'kd-react'
Link  = require 'app/components/common/link'

module.exports = class StartVideoCallLink extends React.Component

  @propTypes =
    isActive : React.PropTypes.bool.isRequired
    onStart  : React.PropTypes.func.isRequired
    onEnd    : React.PropTypes.func.isRequired


  render: ->

    props = if @props.isActive
    then {handler: @props.onEnd, label: 'Leave Video Call'}
    else {handler: @props.onStart, label: 'Join Video Call'}

    <Link className='StartVideoCall-link' onClick={props.handler}>
      <span>
        {props.label}
      </span>
      <i className='StartVideoCall-icon'></i>
    </Link>
