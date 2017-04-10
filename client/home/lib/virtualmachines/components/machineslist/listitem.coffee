kd = require 'kd'
React = require 'app/react'
MachineDetails = require './machinedetails'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'

Machine = require 'app/remote-extensions/machine'
ComputeStack = require 'app/remote-extensions/computestack'

getMachineLinks = require 'app/util/getMachineLinks'


module.exports = class MachinesListItem extends React.Component

  @propTypes =
    machine                : React.PropTypes.instanceOf Machine
    stack                  : React.PropTypes.instanceOf ComputeStack
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
    return null  unless @props.machine.getId() is @state.activeMachine

    <main className="MachinesListItem-machineDetails">
      <MachineDetails
        machine={@props.machine}
        status={@props.status}
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

    { router } = kd.singletons

    if @state.activeMachine is @props.machine.getId()
      return router.handleRoute "/Home/stacks/virtual-machines"

    router.handleRoute getMachineLinks @props.machine, 'dashboard'


  renderIpAddress: ->

    { ipAddress } = @props.machine

    ip = ipAddress or '0.0.0.0'

    title = if ipAddress then ip else '''
      Actual IP address will appear here when this VM is powered on.
      '''

    <div className="MachinesListItem-hostName">
      <div title={title} className='ip-address'>{ip}</div>
    </div>


  renderDetailToggle: ->

    return null  unless @props.shouldRenderDetails

    expanded = if @props.machine.getId() is @state.activeMachine
    then ' expanded'
    else ''

    <div className="MachinesListItem-detailToggle#{expanded}">
      <button
        className='MachinesListItem-detailToggleButton'
        onClick={@bound 'toggle'} />
    </div>


  renderProgressbar: ->

    return  unless @props.percentage

    { status, percentage = 0 } = @props

    return null  if status in ['NotInitialized', 'Stopped']
    return null  if status is 'Running' and percentage is 100

    fullClass = if percentage is 100 then ' full' else ''

    <div className={"SidebarListItem-progressbar#{fullClass}"}>
      <cite style={width: "#{percentage}%"} />
    </div>


  renderStackTitle: ->

    <div className="MachinesListItem-stackLabel">
      <a title={@props.stack.title} href="#" className="HomeAppView--button primary">
        {@props.stack.title}
      </a>
    </div>


  render: ->

    unless @props.machine
      return null

    expanded = if @props.machine.getId() is @state.activeMachine
    then ' expanded'
    else ''

    machineName = @state.expandedMachineLabel if expanded

    <div className="MachinesListItem#{expanded}">
      <header className='MachinesListItem-header'>
        <div
          className="MachinesListItem-machineLabel #{@props.status}"
          onClick={@bound 'toggle'}>
          <div title={machineName or @props.machine.label} className='label'>
            {machineName or @props.machine.label}
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
