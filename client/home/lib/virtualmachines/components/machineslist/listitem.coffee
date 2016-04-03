React = require 'react'
MachineDetails = require './machinedetails'
immutable = require 'immutable'

module.exports = class MachinesListItem extends React.Component

  @propTypes =
    machine              : React.PropTypes.instanceOf(immutable.Map).isRequired
    stack                : React.PropTypes.instanceOf(immutable.Map).isRequired
    shouldRenderDetails  : React.PropTypes.bool
    shouldRenderSpecs    : React.PropTypes.bool
    shouldRenderPower    : React.PropTypes.bool
    shouldRenderAlwaysOn : React.PropTypes.bool
    shouldRenderSharing  : React.PropTypes.bool

  @defaultProps =
    shouldRenderDetails  : yes
    shouldRenderSpecs    : no
    shouldRenderPower    : yes
    shouldRenderAlwaysOn : no
    shouldRenderSharing  : no


  constructor: (props) ->
    super props
    @state = {isDetailOpen: no}


  renderMachineDetails: ->
    return null  unless @props.shouldRenderDetails
    return null  unless @state.isDetailOpen

    <div className="MachinesListItem-machineDetails">
      <MachineDetails
        machine={@props.machine}
        shouldRenderSpecs={@props.shouldRenderSpecs}
        shouldRenderPower={@props.shouldRenderPower}
        shouldRenderAlwaysOn={@props.shouldRenderAlwaysOn}
        shouldRenderSharing={@props.shouldRenderSharing} />
    </div>


  renderDetailToggle: ->

    return null  unless @props.shouldRenderDetails

    toggleOpen = (machineId) => (event) => @setState { isDetailOpen: not @state.isDetailOpen }

    <div className="MachinesListItem-detailToggle">
      <button className="MachinesListItem-detailToggleIcon" onClick={toggleOpen @props.machine.get 'id'}>></button>
    </div>


  render: ->

    <div className="MachinesListItem">
      <div className="MachinesListItem-machineLabel">
        {@props.machine.get 'label'}
      </div>
      <div className="MachinesListItem-hostName">
        {@props.machine.get 'ipAddress'}
      </div>
      <div className="MachinesListItem-stackLabel">
        {@props.stack.get 'title'}
      </div>
      {@renderDetailToggle()}
      {@renderMachineDetails()}
    </div>



