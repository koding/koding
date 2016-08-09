kd = require 'kd'
React = require 'kd-react'
MachineDetails = require './machinedetails'
Machine = require 'app/providers/machine'
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
    onChangeSharingStatus  : React.PropTypes.func
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
    onChangeSharingStatus  : kd.noop
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
        onChangeSharingStatus={@props.onChangeSharingStatus}
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

  renderProgressbar: ->

    return unless  @props.machine

    status     = @props.machine.getIn ['status', 'state']
    percentage = @props.machine.get('percentage') or 0

    return null  if status in [Machine.State.NotInitialized, Machine.State.Stopped]
    return null  if status is Machine.State.Running and percentage is 100

    fullClass  = if percentage is 100 then ' full' else ''

    <div className={"SidebarListItem-progressbar#{fullClass}"}>
      <cite style={width: "#{percentage}%"} />
    </div>


  render: ->

    expanded = if @props.machine.get('label') is @state.selectedMachine
    then ' expanded'
    else ''

    <div className="MachinesListItem#{expanded}">
      <header className='MachinesListItem-header'>
        <div className="MachinesListItem-machineLabel #{@props.machine.getIn ['status', 'state']}">
          <input
            ref='inputbox'
            value={@state.machineLabel}
            className="kdinput text template-title autogrow"
            onChange={@bound 'inputOnChange'}
            onBlur={@bound 'inputOnBlur'}
            onKeyDown={@bound 'inputOnKeyDown'} />
          {@renderProgressbar()}
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
