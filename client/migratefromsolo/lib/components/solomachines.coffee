kd = require 'kd'
React = require 'kd-react'
CheckBox = require 'app/components/common/checkbox'

module.exports = class SoloMachines extends React.Component

  @propTypes = {
    onMachinesConfirm: React.PropTypes.func.isRequired
    onHelpRequest: React.PropTypes.func.isRequired
  }

  constructor: (props) ->

    super props

    @state = {
      machines: [], selectedMachines: {},
      finishedSelection: no, confirmed: no, loading: yes
    }


  componentDidMount: ->

    kd.singletons.computeController.fetchSoloMachines (err, machines) =>
      return  if err
      @setState { loading: no, machines }


  onMachineSelect: (machineId) ->

    { selectedMachines } = @state
    isSelected = selectedMachines[machineId]
    selectedMachines[machineId] = not isSelected

    @setState { selectedMachines }


  onSubmit: (event) ->

    kd.utils.stopDOMEvent event
    @setState { finishedSelection: yes }


  onConfirm: (event) ->

    kd.utils.stopDOMEvent event

    { selectedMachines } = @state

    selectedMachineIds = Object.keys(selectedMachines).filter (id) -> selectedMachines[id]

    @setState { confirmed: yes }
    @props.onMachinesConfirm selectedMachineIds


  onFinishCancel: ->

    @setState { finishedSelection: no }


  renderMachines: ->

    if @state.loading

      <div className='GenericMessage'>
        <p>Loading...</p>
      </div>

    else if @state.machines.length is 0

      message = """
        You don't have any Koding VMs that can be migrated to your Team
        Please contact with support if you need an assistance
      """

      <div className='GenericMessage'>
        <p>{message}</p>
        <div className='ButtonContainer'>
          <button className='GenericButton' onClick={@props.onHelpRequest}>Contact Support</button>
        </div>
      </div>

    else

      @state.machines.map (machine) =>
        isSelected = @state.selectedMachines[machine._id]
        <ListItem
          key={machine._id}
          machine={machine}
          finishedSelection={@state.finishedSelection}
          onSelect={@lazyBound 'onMachineSelect', machine._id}
          isSelected={isSelected} />


  renderButton: ->

    selectedMachineCount = Object.keys(@state.selectedMachines).length

    if @state.confirmed
      null
    else if @state.finishedSelection
      <div className="GenericButtonGroup">
        <button className='GenericButton' onClick={@bound 'onConfirm'}>START MIGRATING</button>
        <button className='GenericButton alternate' onClick={@bound 'onFinishCancel'}>CANCEL</button>
      </div>
    else
      <button disabled={not selectedMachineCount} className='GenericButton' onClick={@bound 'onSubmit'}>SELECT MACHINES</button>


  render: ->

    className = 'SoloMachinesList'
    className += ' disabled'  if @state.finishedSelection or @state.confirmed

    buttonState = if @state.machines.length is 0 then 'hidden' else 'ButtonContainer'

    <div className='SoloMachinesListContainer'>
      <ul className={className}>
        {@renderMachines()}
      </ul>
      <div className={buttonState}>
        {@renderButton()}
      </div>
    </div>


ListItem = ({ machine, isSelected, onSelect, finishedSelection }) ->

  <div className="SoloMachinesListItem">
    <header>
      <label className="SoloMachinesListItem-machineLabel">
        <CheckBox disabled={finishedSelection} onClick={onSelect} checked={!!isSelected} />
        { machine.label }
      </label>
      <div className="SoloMachinesListItem-hostName">{machine.ipAddress}</div>
    </header>
  </div>


