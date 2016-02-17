kd         = require 'kd'
React      = require 'kd-react'
Link       = require 'app/components/common/link'
classnames = require 'classnames'

module.exports = class StartVideoCallLink extends React.Component

  @propTypes =
    isActive : React.PropTypes.bool.isRequired
    onStart  : React.PropTypes.func.isRequired
    onEnd    : React.PropTypes.func.isRequired
    iconOnly : React.PropTypes.bool


  @defaultProps =
    iconOnly : no


  renderWithLabel: ->

    props = if @props.isActive
    then {handler: @props.onEnd, label: 'Leave Video Call'}
    else {handler: @props.onStart, label: 'Join Video Call'}

    <Link className='StartVideoCall-link' onClick={props.handler}>
      <span>
        {props.label}
      </span>
      <i className='StartVideoCall-icon'></i>
    </Link>


  renderIconOnly: ->

    handler = if @props.isActive
    then @props.onEnd
    else @props.onStart

    <button className='Button StartVideoCall-button' onClick={handler}>
      <i className='StartVideoCall-icon'></i>
    </button>


  render: ->

    className = classnames
      'StartVideoCallLink': yes
      'is-videoActive': @props.isActive
      'is-iconOnly': @props.iconOnly

    <div className={className}>
      {if @props.iconOnly then @renderIconOnly() else @renderWithLabel()}
    </div>

