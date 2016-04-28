_                   = require 'lodash'
kd                  = require 'kd'
React               = require 'kd-react'
classnames          = require 'classnames'
GenericToggler      = require './generictoggler'
immutable           = require 'immutable'
Machine             = require 'app/providers/machine'
SharingAutocomplete = require './sharingautocomplete'

module.exports = class MachineDetails extends React.Component

  @propTypes =
    machine              : React.PropTypes.instanceOf(immutable.Map).isRequired
    shouldRenderSpecs    : React.PropTypes.bool
    shouldRenderPower    : React.PropTypes.bool
    shouldRenderAlwaysOn : React.PropTypes.bool
    shouldRenderSharing  : React.PropTypes.bool
    onChangeAlwaysOn     : React.PropTypes.func
    onChangePowerStatus  : React.PropTypes.func
    onSharedWithUser     : React.PropTypes.func


  @defaultProps =
    shouldRenderSpecs    : no
    shouldRenderPower    : yes
    shouldRenderAlwaysOn : no
    shouldRenderSharing  : no
    onChangeAlwaysOn     : kd.noop
    onChangePowerStatus  : kd.noop
    onSharedWithUser     : kd.noop


  constructor: (props) ->

    super props
    @state = {}


  onSharingToggle: (checked) ->

    @setState { isShared : checked }


  isShared: ->  @state.isShared ? @props.machine.get('sharedUsers')?.size > 0


  renderSpecs: ->

    return  unless @props.shouldRenderSpecs

    specs = generateSpecs @props.machine

    children = specs.map (spec) ->
      <div key={spec} className="SingleSpecItem">{spec}</div>

    <div className='MachineDetails-SpecsList'>{children}</div>


  renderPowerToggler: ->

    return  unless @props.shouldRenderPower

    { Running, Starting } = Machine.State
    isRunning = @props.machine.getIn([ 'status', 'state' ]) in [ Running, Starting ]

    <GenericToggler
      title='VM Power'
      description='Turn your machine on or off from here'
      checked={isRunning}
      onToggle={@props.onChangePowerStatus} />


  renderAlwaysOnToggler: ->

    return  unless @props.shouldRenderAlwaysOn

    <GenericToggler
      title='Always On'
      description='Keep this machine running indefinitely'
      checked={@props.machine.getIn [ 'meta', 'alwaysOn' ]}
      onToggle={@props.onChangeAlwaysOn} />


  renderSharingToggler: ->

    return  unless @props.shouldRenderSharing

    <GenericToggler
      title='VM Sharing'
      description='Teammates with this link can access my VM'
      checked={@isShared()}
      onToggle={@bound 'onSharingToggle'}>
        {@renderSharingDetails()}
    </GenericToggler>


  renderSharingDetails: ->

    return  unless @isShared()

    <div className='MachineSharingDetails'>
      <SharingAutocomplete machineId={@props.machine.get '_id'} onSelect={@props.onSharedWithUser} />
    </div>


  render: ->

    <div className='MachineDetails'>
      {@renderSpecs()}
      {@renderPowerToggler()}
      {@renderAlwaysOnToggler()}
      {@renderSharingToggler()}
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

