kd = require 'kd'
ProvidersView = require 'stacks/views/stacks/providersview'
ReactView = require 'app/react/reactview'
React = require 'kd-react'
getGroup = require 'app/util/getGroup'

module.exports = class MigrateFromSoloAppView extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass or= kd.utils.curry 'MigrateFromSoloAppView', options.cssClass
    options.width ?= 1000
    options.height ?= '90%'
    options.overlay ?= yes

    super options, data

    @credential = @machines = null

    console.log 'naptin fff'

    @providersView = new ProvidersView { provider: 'aws' }
    @soloVmsList = new SoloVmsList
    @progressBar = new kd.ProgressBarView { initial: 1 }

    @addSubView @providersView
    @addSubView @soloVmsList

    @providersView.on 'ItemSelected', (credentialItem) =>
      @credential = credentialItem.getData()
      @switchToVmsList()

    @soloVmsList.on 'MachinesConfirmed', (machines) =>
      @machines = machines
      @switchToMigrationProcess()


  switchToCredentials: ->

    @providersView.show()
    @soloVmsList.hide()


  switchToVmsList: ->

    @providersView.hide()
    @soloVmsList.show()


  switchToMigrationProcess: ->

    { computeController } = kd.singletons
    { slug } = getGroup()

    # @providersView.hide()
    # @soloVmsList.hide()
    # @progressBar.show()

    computeController.getKloud().migrate(
      provider: 'aws'
      groupName: slug
      machines: @machines
      identifier: @credential.identifier
    ).then ({ eventId }) ->

      splitted = eventId.split '-'

      computeController.eventListener.addListener "migrate-#{slug}", splitted.last




class SoloVmsList extends ReactView

  onMachinesConfirm: (machines) ->

    @emit 'MachinesConfirmed', machines


  renderReact: ->
    <SoloVms onMachinesConfirm={@bound 'onMachinesConfirm'} />


class SoloVms extends React.Component

  constructor: (props) ->

    super props

    @state = { machines: [], selectedMachines: {}, finishedSelection: no }

    console.log {@state}


  componentDidMount: ->

    kd.singletons.computeController.fetchSoloMachines (err, machines) =>
      return  if err
      @setState { machines }


  onMachineSelect: (machineId) ->

    console.log {machineId}

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

    @props.onMachinesConfirm selectedMachineIds


  renderMachines: ->

    @state.machines.map (machine) =>
      isSelected = @state.selectedMachines[machine._id]
      console.log {isSelected}
      <ListItem
        key={machine._id}
        machine={machine}
        finishedSelection={@state.finishedSelection}
        onSelect={@lazyBound 'onMachineSelect', machine._id}
        isSelected={isSelected} />


  renderButton: ->

    if @state.finishedSelection
      <button onClick={@bound 'onConfirm'}>START MIGRATING</button>
    else
      <button onClick={@bound 'onSubmit'}>SELECT VMs</button>


  render: ->

    <div>
      <ul>
        {@renderMachines()}
      </ul>
      {@renderButton()}
    </div>


ListItem = ({ machine, isSelected, onSelect, finishedSelection }) ->

  <div>
    <label className=''>
      <input
        type='checkbox'
        disabled={finishedSelection}
        name={machine._id}
        onChange={onSelect}
        value={!!isSelected} />
      { machine.label }
    </label>
  </div>


