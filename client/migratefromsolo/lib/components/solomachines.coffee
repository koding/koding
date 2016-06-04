kd = require 'kd'
React = require 'kd-react'
CheckBox = require 'app/components/common/checkbox'

module.exports = class SoloMachines extends React.Component

  @propTypes = { onMachinesConfirm: React.PropTypes.func.isRequired }

  constructor: (props) ->

    super props

    @state = { machines: [], selectedMachines: {}, finishedSelection: no, confirmed: no }


  componentDidMount: ->

    kd.singletons.computeController.fetchSoloMachines (err, machines) =>
      return  if err
      @setState { machines }


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

    @state.machines.map (machine) =>
      isSelected = @state.selectedMachines[machine._id]
      <ListItem
        key={machine._id}
        machine={machine}
        finishedSelection={@state.finishedSelection}
        onSelect={@lazyBound 'onMachineSelect', machine._id}
        isSelected={isSelected} />


  renderButton: ->

    if @state.confirmed
      null
    else if @state.finishedSelection
      <div className="GenericButtonGroup">
        <button className='GenericButton' onClick={@bound 'onConfirm'}>START MIGRATING</button>
        <button className='GenericButton secondary' onClick={@bound 'onFinishCancel'}>CANCEL</button>
      </div>
    else
      <button className='GenericButton' onClick={@bound 'onSubmit'}>SELECT MACHINES</button>


  render: ->

    className = 'SoloMachinesList'
    className += ' disabled'  if @state.finishedSelection or @state.confirmed

    <div>
      <ul className={className}>
        {@renderMachines()}
      </ul>
      {@renderButton()}
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


