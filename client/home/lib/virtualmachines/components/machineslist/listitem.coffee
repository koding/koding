kd = require 'kd'
React = require 'kd-react'
MachineDetails = require './machinedetails'
immutable = require 'immutable'
VirtualMachinesSelectedMachineFlux = require 'home/virtualmachines/flux/selectedmachine'
KDReactorMixin = require 'app/flux/base/reactormixin'

module.exports = class MachinesListItem extends React.Component

  @propTypes =
    machine                : React.PropTypes.instanceOf(immutable.Map).isRequired
    stack                  : React.PropTypes.instanceOf(immutable.Map).isRequired
    shouldRenderDetails    : React.PropTypes.bool
    shouldRenderSpecs      : React.PropTypes.bool
    shouldRenderPower      : React.PropTypes.bool
    shouldRenderDisconnect : React.PropTypes.bool
    shouldRenderAlwaysOn   : React.PropTypes.bool
    shouldRenderSharing    : React.PropTypes.bool
    onChangeAlwaysOn       : React.PropTypes.func
    onChangePowerStatus    : React.PropTypes.func
    onDetailOpen           : React.PropTypes.func
    onSharedWithUser       : React.PropTypes.func
    onUnsharedWithUser     : React.PropTypes.func
    onDisconnectVM         : React.PropTypes.func

  @defaultProps =
    shouldRenderDetails    : yes
    shouldRenderSpecs      : no
    shouldRenderPower      : no
    shouldRenderDisconnect : no
    shouldRenderAlwaysOn   : no
    shouldRenderSharing    : no
    onChangeAlwaysOn       : kd.noop
    onChangePowerStatus    : kd.noop
    onDetailOpen           : kd.noop
    onSharedWithUser       : kd.noop
    onUnsharedWithUser     : kd.noop
    onDisconnectVM         : kd.noop

  getDataBindings: ->

    return {
      selectedMachine: VirtualMachinesSelectedMachineFlux.getters.selectedMachine
    }


  renderMachineDetails: ->

    return null  unless @props.shouldRenderDetails
    return null  unless @props.machine.get('label') is @state.selectedMachine


    <main className="MachinesListItem-machineDetails">
      <MachineDetails
        machine={@props.machine}
        shouldRenderSpecs={@props.shouldRenderSpecs}
        shouldRenderPower={@props.shouldRenderPower}
        shouldRenderDisconnect={@props.shouldRenderDisconnect}
        shouldRenderAlwaysOn={@props.shouldRenderAlwaysOn}
        shouldRenderSharing={@props.shouldRenderSharing}
        onChangeAlwaysOn={@props.onChangeAlwaysOn}
        onChangePowerStatus={@props.onChangePowerStatus}
        onSharedWithUser={@props.onSharedWithUser}
        onUnsharedWithUser={@props.onUnsharedWithUser}
        onDisconnectVM={@props.onDisconnectVM}
      />
    </main>


  toggle: (event) ->

    if @state.selectedMachine is @props.machine.get 'label'
      return kd.singletons.router.handleRoute "/Home/Stacks/virtual-machines"

    kd.singletons.router.handleRoute "/Home/Stacks/virtual-machines/#{@props.machine.get 'label'}"



  renderIpAddress: ->

    hasIp = @props.machine.get 'ipAddress'
    ip    = hasIp or '0.0.0.0'
    title = if hasIp then '' else 'Actual IP address will appear here when this VM is powered on.'

    <div title={title} className="MachinesListItem-hostName">{ip}</div>


  renderDetailToggle: ->

    return null  unless @props.shouldRenderDetails

    expanded = if @props.machine.get('label') is @state.selectedMachine
    then ' expanded'
    else ''

    <div className="MachinesListItem-detailToggle#{expanded}">
      <button className='MachinesListItem-detailToggleButton' onClick={@bound 'toggle'}></button>
    </div>


  render: ->

    expanded = if @props.machine.get('label') is @state.selectedMachine
    then ' expanded'
    else ''

    <div className="MachinesListItem#{expanded}">
      <header>
        <div
          className="MachinesListItem-machineLabel #{@props.machine.getIn ['status', 'state']}"
          onClick={@bound 'toggle'}>
          {@props.machine.get 'label'}
        </div>
        {@renderIpAddress()}
        <div className="MachinesListItem-stackLabel">
          <a href="#" className="HomeAppView--button primary">{@props.stack.get 'title'}</a>
        </div>
        {@renderDetailToggle()}
      </header>
      {@renderMachineDetails()}
    </div>

MachinesListItem.include [KDReactorMixin]
