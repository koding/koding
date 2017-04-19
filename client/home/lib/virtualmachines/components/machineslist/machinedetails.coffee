_                   = require 'lodash'
kd                  = require 'kd'
globals             = require 'globals'
React               = require 'app/react'
classnames          = require 'classnames'
GenericToggler      = require './generictoggler'
immutable           = require 'immutable'
SharingAutocomplete = require './sharing/autocomplete'
SharingUserList     = require './sharing/userlist'
ContentModal        = require 'app/components/contentModal'
EnvironmentFlux     = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'
getMachineLinks = require 'app/util/getMachineLinks'

Machine = require 'app/remote-extensions/machine'

module.exports = class MachineDetails extends React.Component

  @propTypes =
    machine                : React.PropTypes.instanceOf Machine
    shouldRenderSpecs      : React.PropTypes.bool
    shouldRenderPower      : React.PropTypes.bool
    shouldRenderAlwaysOn   : React.PropTypes.bool
    shouldRenderSharing    : React.PropTypes.bool
    shouldRenderDisconnect : React.PropTypes.bool
    onChangeAlwaysOn       : React.PropTypes.func
    onChangePowerStatus    : React.PropTypes.func
    onChangeSharingStatus  : React.PropTypes.func
    onSharedWithUser       : React.PropTypes.func
    onUnsharedWithUser     : React.PropTypes.func
    onDisconnectVM         : React.PropTypes.func


  @defaultProps =
    shouldRenderSpecs      : no
    shouldRenderPower      : no
    shouldRenderAlwaysOn   : no
    shouldRenderSharing    : no
    shouldRenderDisconnect : no
    onChangeAlwaysOn       : kd.noop
    onChangePowerStatus    : kd.noop
    onChangeSharingStatus  : kd.noop
    onSharedWithUser       : kd.noop
    onUnsharedWithUser     : kd.noop
    onDisconnectVM         : kd.noop


  constructor: (props) ->

    super props

    @state =
      machineLabel: @props.machine.label
      editNameClassName: 'GenericToggler-button'
      inputClasssName: 'kdinput text edit-name hidden'

    @input = null


  getDataBindings: ->
    return {
      expandedMachineLabel: EnvironmentFlux.getters.expandedMachineLabelStore
    }


  onSharingToggle: (checked) ->

    if checked
      return @setState { isShared: yes }

    unless @props.machine.getSharedUsers().length
      @setState { isShared: no }
      @props.onChangeSharingStatus no
      return

    modal          = new ContentModal
      title        : 'Are you sure?'
      content      : 'Once you disable sharing all of the participants will lose access to this VM immediately.'
      cssClass     : 'content-modal'
      overlay      : yes
      buttons      :
        No         :
          title    : 'Cancel'
          cssClass : 'solid medium'
          callback : =>
            @setState { isShared: yes }
            modal.destroy()
        Yes        :
          title    : 'Disable Sharing'
          cssClass : 'solid medium'
          callback : =>
            @setState { isShared: no }
            @props.onChangeSharingStatus no
            modal.destroy()



  isShared: ->

    @state.isShared ? @props.machine.getSharedUsers().length > 0


  status: -> @props.status or @props.machine.getStatus()


  renderSpecs: ->

    return  unless @props.shouldRenderSpecs

    specs = generateSpecs @props.machine

    className = 'MachineDetails-SpecsList'
    if @status() in [ 'Starting', 'Stopping' ]
      className = 'MachineDetails-SpecsList notReady'

    children = specs.map (spec) ->
      <div key={spec} className="SingleSpecItem">{spec}</div>

    <div className={className}>{children}</div>


  renderDisconnectToggler: ->

    return  unless @props.shouldRenderDisconnect

    <GenericToggler
      title='VM Disconnect'
      description='Turn your machine off from here'
      checked={@status() in [ 'Running', 'Starting' ]}
      disabled={not (@status() in [ 'Running', 'Stopped' ])}
      onToggle={@props.onDisconnectVM} />


  renderPowerToggler: ->

    return  unless @props.shouldRenderPower

    <GenericToggler
      title='VM Power'
      description='Turn your machine on or off from here'
      checked={@status() in [ 'Running', 'Starting' ]}
      disabled={not (@status() in [ 'Running', 'Stopped' ])}
      onToggle={@props.onChangePowerStatus} />


  renderAlwaysOnToggler: ->

    return  unless @props.shouldRenderAlwaysOn

    <GenericToggler
      title='Always On'
      description='Keep this machine running indefinitely'
      checked={@props.machine.isAlwaysOn()}
      disabled={@status() is 'NotInitialized'}
      onToggle={@props.onChangeAlwaysOn} />


  renderSharingToggler: ->

    return  unless @props.shouldRenderSharing

    <GenericToggler
      title='VM Sharing'
      description='Share my VM with teammates'
      checked={@isShared()}
      disabled={@status() isnt 'Running'}
      onToggle={@bound 'onSharingToggle'}>
        {@renderSharingDetails()}
    </GenericToggler>


  renderSharingDetails: ->

    return  unless @isShared()

    { machine } = @props

    <div className='MachineSharingDetails'>

      <SharingAutocomplete.Container
        machineId={machine.getId()}
        onSelect={@props.onSharedWithUser} />

      <SharingUserList
        users={machine.getSharedUsers()}
        onUserRemove={@props.onUnsharedWithUser} />

    </div>


  renderBuildLog: ->

    { machine } = @props

    return  unless machine

    state = machine.getStatus()

    isMachineRunning = state is 'Running'

    description = 'Logs that were created while we built your VM.'
    description = 'Turn on your VM to see the build logs.' unless isMachineRunning

    <GenericToggler
      title='Build Logs'
      description={description}
      buttonTitle='Show Build Logs'
      button={yes}
      onToggle={kd.noop}
      onClickButton={@bound 'onClickBuildLog'}
      machineState={isMachineRunning} />


  renderEditName: ->

    return  unless @props.shouldRenderEditName
    pullRight = 'pull-right'
    unless @state.inputClasssName.indexOf('hidden') > 0
      pullRight = 'pull-right with-input'

    <div className='GenericToggler'>
      <div className='GenericToggler-top edit-name'>
        <EditVMNameDescription />
        <div className={pullRight}>
          <EditNameButton cssClass={@state.editNameClassName} callback={@bound 'showInputBox'} />
          <input
            ref={(input) => @input = input}
            value={@state.machineLabel}
            className={@state.inputClasssName}
            onChange={@bound 'onInputChange'}
            onBlur={@bound 'onInputBlur'}
            onKeyDown={@bound 'onInputKeyDown'} />
        </div>
      </div>
    </div>


  showInputBox: ->

    @setState
      editNameClassName: 'GenericToggler-button hidden'
      inputClasssName: 'kdinput text edit-name'

    kd.utils.defer => @input?.focus()


  onInputBlur: (event) ->

    @setMachineLabel()
    @setState
      editNameClassName: 'GenericToggler-button'
      inputClasssName: 'kdinput text edit-name hidden'


  onInputKeyDown: (event) ->

    if event.keyCode is 13
      @input.blur()


  onInputChange: (event) ->

    { value: machineLabel } = event.target
    @setState { machineLabel: machineLabel }
    EnvironmentFlux.actions.loadExpandedMachineLabel machineLabel


  setMachineLabel: ->

    unless @state.machineLabel
      @setState { machineLabel: @props.machine.label}
      return

    @props.machine.setLabel @state.machineLabel, (err) =>
      if err
        @setState { machineLabel: @props.machine.label }
        return new kd.NotificationView
          title: 'Something went wrong',
          duration: 2000

      kd.singletons.router.handleRoute \
        getMachineLinks @props.machine, 'dashboard'


  onClickBuildLog: (e) ->

    kd.singletons.computeController.showBuildLogs @props.machine, 0


  render: ->

    <div className='MachineDetails'>
      {@renderSpecs()}
      {@renderEditName()}
      {@renderPowerToggler()}
      {@renderAlwaysOnToggler()}
      {@renderDisconnectToggler()}
      {@renderSharingToggler()}
      {@renderBuildLog()}
    </div>


generateSpecs = (machine) ->

  providerName = machine.meta?.type ? 'vagrant'

  configs = globals.config.providers
  { instanceTypes } = configs[providerName]
  if instanceTypes
    instanceType = machine.meta?.instance_type ? instanceTypes['base-vm']

    instanceData = instanceTypes[instanceType]
    { ram, cpu } = instanceData ? instanceTypes[instanceTypes['base-vm']]

  size = machine.meta?.storage_size
  disk = if size then "#{size}GB HDD" else null

  return [providerName, instanceType, ram, cpu, disk].filter(Boolean)


EditVMNameDescription = ->
  <div className='pull-left'>
    <div className='GenericToggler-title'>
      Edit VM Name
    </div>
    <div className='GenericToggler-description'>
      You can change your VM name here
    </div>
  </div>


EditNameButton = ({ cssClass, callback }) ->

  <div className={cssClass}>
    <a
      className='custom-link-view HomeAppView--button primary fr'
      href='#' onClick={callback}>
      <span className='title'>Edit Name</span>
    </a>
  </div>


MachineDetails.include [KDReactorMixin]
