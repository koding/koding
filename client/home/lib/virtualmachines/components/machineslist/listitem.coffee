kd = require 'kd'
React = require 'app/react'
MachineDetails = require './machinedetails'
immutable = require 'immutable'
KDReactorMixin = require 'app/flux/base/reactormixin'
EnvironmentFlux = require 'app/flux/environment'
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
    shouldRenderEditName   : React.PropTypes.bool
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
    shouldRenderEditName   : no
    onChangeAlwaysOn       : kd.noop
    onChangePowerStatus    : kd.noop
    onChangeSharingStatus  : kd.noop
    onSharedWithUser       : kd.noop
    onUnsharedWithUser     : kd.noop
    onDisconnectVM         : kd.noop


  getDataBindings: ->

    return {
      activeMachine: EnvironmentFlux.getters.activeMachine
      expandedMachineLabel: EnvironmentFlux.getters.expandedMachineLabelStore
    }


  renderMachineDetails: ->

    return null  unless @props.shouldRenderDetails
    return null  unless @props.machine.get('_id') is @state.activeMachine
    <main className="MachinesListItem-machineDetails">
      <MachineDetails
        machine={@props.machine}
        shouldRenderSpecs={@props.shouldRenderSpecs}
        shouldRenderPower={@props.shouldRenderPower}
        shouldRenderDisconnect={@props.shouldRenderDisconnect}
        shouldRenderAlwaysOn={@props.shouldRenderAlwaysOn}
        shouldRenderSharing={@props.shouldRenderSharing}
        shouldRenderEditName={@props.shouldRenderEditName}
        onChangeAlwaysOn={@props.onChangeAlwaysOn}
        onChangePowerStatus={@props.onChangePowerStatus}
        onChangeSharingStatus={@props.onChangeSharingStatus}
        onSharedWithUser={@props.onSharedWithUser}
        onUnsharedWithUser={@props.onUnsharedWithUser}
        onDisconnectVM={@props.onDisconnectVM}
      />
    </main>


  toggle: (event) ->

    if @state.activeMachine is @props.machine.get '_id'
      return kd.singletons.router.handleRoute "/Home/stacks/virtual-machines"

    kd.singletons.router.handleRoute "/Home/stacks/virtual-machines/#{@props.machine.get '_id'}"


  renderIpAddress: ->

    hasIp = @props.machine.get 'ipAddress'
    ip    = hasIp or '0.0.0.0'
    title = if hasIp then ip else 'Actual IP address will appear here when this VM is powered on.'

    <div className="MachinesListItem-hostName">
      <div title={title} className='ip-address'>{ip}</div>
    </div>


  renderDetailToggle: ->

    return null  unless @props.shouldRenderDetails

    expanded = if @props.machine.get('_id') is @state.activeMachine
    then ' expanded'
    else ''

    <div className="MachinesListItem-detailToggle#{expanded}">
      <button className='MachinesListItem-detailToggleButton' onClick={@bound 'toggle'}></button>
    </div>

  renderProgressbar: ->

    return unless  @props.machine

    status     = @props.machine.getIn ['status', 'state']
    percentage = @props.machine.get('percentage') or 0

    return null  if status in ['NotInitialized', 'Stopped']
    return null  if status is 'Running' and percentage is 100

    fullClass  = if percentage is 100 then ' full' else ''

    <div className={"SidebarListItem-progressbar#{fullClass}"}>
      <cite style={width: "#{percentage}%"} />
    </div>



  renderStackTitle: ->

    <div className="MachinesListItem-stackLabel">
      <a title={@props.stack.get 'title'} href="#" className="HomeAppView--button primary">
        {@props.stack.get 'title'}
      </a>
    </div>


  render: ->

    expanded = if @props.machine.get('_id') is @state.activeMachine
    then ' expanded'
    else ''
    machineName = @state.expandedMachineLabel if expanded

    <div className="MachinesListItem#{expanded}">
      <header className='MachinesListItem-header'>
        <div
          className="MachinesListItem-machineLabel #{@props.machine.getIn ['status', 'state']}"
          onClick={@bound 'toggle'}>
          <div title={machineName or @props.machine.get 'label'} className='label'>
            {machineName or @props.machine.get 'label'}
          </div>
          {@renderProgressbar()}
        </div>
        {@renderIpAddress()}
        {@renderStackTitle()}
        {@renderDetailToggle()}
      </header>
      {@renderMachineDetails()}
    </div>

MachinesListItem.include [KDReactorMixin]
