_                   = require 'lodash'
kd                  = require 'kd'
React               = require 'kd-react'
classnames          = require 'classnames'
GenericToggler      = require './generictoggler'
immutable           = require 'immutable'
Machine             = require 'app/providers/machine'
SharingAutocomplete = require './sharing/autocomplete'
SharingUserList     = require './sharing/userlist'
ContentModal        = require 'app/components/contentModal'
FSHelper = require 'app/util/fs/fshelper'
envDataProvider      = require 'app/userenvironmentdataprovider'
remote  = require('app/remote').getInstance()
module.exports = class MachineDetails extends React.Component

  @propTypes =
    machine                : React.PropTypes.instanceOf(immutable.Map).isRequired
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
    @state = {}


  onSharingToggle: (checked) ->

    return @setState { isShared: yes }  if checked

    unless @props.machine.get('sharedUsers').size
      @setState { isShared: no }
      @props.onChangeSharingStatus no
      return

    modal          = new ContentModal
      title        : 'Are you sure?'
      content      : 'Once you turn off sharing all of the participants will lose access to this VM immediately.'
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
          title    : 'Turn Off'
          cssClass : 'solid medium'
          callback : =>
            @setState { isShared: no }
            @props.onChangeSharingStatus no
            modal.destroy()



  isShared: ->

    @state.isShared ? @props.machine.get 'isShared'


  status: -> @props.machine.getIn [ 'status', 'state' ]


  renderSpecs: ->

    return  unless @props.shouldRenderSpecs

    specs = generateSpecs @props.machine

    children = specs.map (spec) ->
      <div key={spec} className="SingleSpecItem">{spec}</div>

    <div className='MachineDetails-SpecsList'>{children}</div>


  renderDisconnectToggler: ->

    return  unless @props.shouldRenderDisconnect

    { Running, Starting, Stopped } = Machine.State

    <GenericToggler
      title='VM Disconnect'
      description='Turn your machine off from here'
      checked={@status() in [ Running, Starting ]}
      disabled={not (@status() in [ Running, Stopped ])}
      onToggle={@props.onDisconnectVM} />


  renderPowerToggler: ->

    return  unless @props.shouldRenderPower

    { Running, Starting, Stopped } = Machine.State

    <GenericToggler
      title='VM Power'
      description='Turn your machine on or off from here'
      checked={@status() in [ Running, Starting ]}
      disabled={not (@status() in [ Running, Stopped ])}
      onToggle={@props.onChangePowerStatus} />


  renderAlwaysOnToggler: ->

    return  unless @props.shouldRenderAlwaysOn

    { NotInitialized } = Machine.State

    <GenericToggler
      title='Always On'
      description='Keep this machine running indefinitely'
      checked={@props.machine.getIn [ 'meta', 'alwaysOn' ]}
      disabled={@status() is NotInitialized}
      onToggle={@props.onChangeAlwaysOn} />


  renderSharingToggler: ->

    return  unless @props.shouldRenderSharing

    { Running } = Machine.State

    <GenericToggler
      title='VM Sharing'
      description='Share my VM with teammates'
      checked={@isShared()}
      disabled={@status() isnt Running}
      onToggle={@bound 'onSharingToggle'}>
        {@renderSharingDetails()}
    </GenericToggler>


  renderSharingDetails: ->

    return  unless @isShared()

    { machine } = @props
    <div className='MachineSharingDetails'>
      <SharingAutocomplete.Container machineId={machine.get '_id'} onSelect={@props.onSharedWithUser} />
      <SharingUserList users={machine.get 'sharedUsers'} onUserRemove={@props.onUnsharedWithUser} />
    </div>

  renderBuildLog: ->

    { machine } = @props

    return  unless machine

    state = machine.getIn ['status', 'state']
    isMachineRunning = state is 'Running'

    description = 'Logs that were created while we built your VM.'

    description = 'Turn on your VM to see the build logs.' unless isMachineRunning


    <GenericToggler
      title='Build Logs'
      description={description}
      buttonTitle='Show Build Logs'
      button=yes
      onToggle={kd.noop}
      onClickButton={@bound 'onClickBuildLog'}
      machineState={isMachineRunning} />


  onClickBuildLog: (e) ->

    machineUId = @props.machine.get 'uid'
    path = '/var/log/cloud-init-output.log'
    kd.singletons.router.handleRoute "/IDE/#{@props.machine.get 'label'}"

    { computeController } = kd.singletons
    machine    = computeController.findMachineFromMachineUId machineUId
    tailOffset = 0
    computeController.showBuildLogs machine, tailOffset


  render: ->

    <div className='MachineDetails'>
      {@renderSpecs()}
      {@renderPowerToggler()}
      {@renderAlwaysOnToggler()}
      {@renderDisconnectToggler()}
      {@renderSharingToggler()}
      {@renderBuildLog()}
    </div>


generateSpecs = (machine) ->

  jMachine = machine.toJS()

  specs = []

  size = jMachine.meta?.storage_size

  specs.push provider = jMachine.provider
  specs.push type = jMachine.meta?.instance_type ? 't2.micro'
  specs.push ram  = {
    't2.nano'   : '512MB RAM'
    't2.micro'  : '1GB RAM'
    't2.medium' : '4GB RAM'
  }[type] ? '1GB RAM'
  specs.push cpu = '1x CPU'
  specs.push disk = if size? then "#{size}GB HDD" else 'N/A'

  return specs

