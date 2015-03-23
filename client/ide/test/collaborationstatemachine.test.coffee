{ expect } = require 'chai'

CollabStateMachine = require '../lib/collaboration/collaborationstatemachine'

describe 'CollaborationStateMachine', ->

  it 'has following states', ->

    machine = new CollabStateMachine

    { states } = machine

    expect(states['Loading']).to.be.ok
    expect(states['ErrorLoading']).to.be.ok
    expect(states['Resuming']).to.be.ok
    expect(states['NotStarted']).to.be.ok
    expect(states['Preparing']).to.be.ok
    expect(states['Prepared']).to.be.ok
    expect(states['Creating']).to.be.ok
    expect(states['ErrorCreating']).to.be.ok
    expect(states['Active']).to.be.ok
    expect(states['Ending']).to.be.ok


  it 'tests Loading state transitions', ->

    machine = newSimpleMachine()
    expect(machine.state).to.equal 'Loading'

    legalStates = ['NotStarted', 'ErrorLoading', 'Resuming']
    illegalStates = [
      'Active', 'Preparing', 'Prepared', 'Creating'
      'ErrorCreating', 'Ending', 'Loading'
    ]

    assertLegalTransitions newSimpleMachine, legalStates
    assertIllegalTransitions newSimpleMachine, illegalStates


  it 'tests Resuming state transitions', ->

    legalStates = ['Active']
    illegalStates = [
      'Loading', 'ErrorLoading', 'Resuming', 'NotStarted'
      'Preparing', 'Prepared', 'Creating', 'ErrorCreating', 'Ending'
    ]

    assertLegalTransitions resumingMachine, legalStates
    assertIllegalTransitions resumingMachine, illegalStates


  it 'tests ErrorLoading state transitions', ->

    legalStates = ['Loading']
    illegalStates = [
      'Active', 'ErrorLoading', 'Resuming', 'NotStarted'
      'Preparing', 'Prepared', 'Creating', 'ErrorCreating', 'Ending'
    ]

    assertLegalTransitions errorLoadingMachine, legalStates
    assertIllegalTransitions errorLoadingMachine, illegalStates


  it 'tests NotStarted state transitions', ->

    legalStates = ['Preparing']
    illegalStates = [
      'Active', 'ErrorLoading', 'Resuming', 'NotStarted'
      'Loading', 'Creating', 'ErrorCreating', 'Ending', 'Prepared'
    ]

    assertLegalTransitions notStartedMachine, legalStates
    assertIllegalTransitions notStartedMachine, illegalStates


  it 'tests Preparing state transitions', ->

    legalStates = ['Prepared']
    illegalStates = [
      'Active', 'ErrorLoading', 'Resuming', 'NotStarted'
      'Loading', 'Creating', 'ErrorCreating', 'Ending', 'Preparing'
    ]

    assertLegalTransitions preparingMachine, legalStates
    assertIllegalTransitions preparingMachine, illegalStates


  it 'tests Prepared state transitions', ->

    legalStates = ['Creating']
    illegalStates = [
      'Active', 'ErrorLoading', 'Resuming', 'NotStarted'
      'Loading', 'Prepared', 'ErrorCreating', 'Ending', 'Preparing'
    ]

    assertLegalTransitions preparedMachine, legalStates
    assertIllegalTransitions preparedMachine, illegalStates


  it 'tests Creating state transitions', ->

    legalStates = ['Active', 'ErrorCreating']
    illegalStates = [
      'Creating', 'ErrorLoading', 'Resuming', 'NotStarted'
      'Loading', 'Prepared', 'Ending', 'Preparing'
    ]

    assertLegalTransitions creatingMachine, legalStates
    assertIllegalTransitions creatingMachine, illegalStates


  it 'tests ErrorCreating state transitions', ->

    legalStates = ['NotStarted', 'Creating']
    illegalStates = [
      'ErrorCreating', 'ErrorLoading', 'Resuming', 'Active'
      'Loading', 'Prepared', 'Ending', 'Preparing'
    ]

    assertLegalTransitions errorCreatingMachine, legalStates
    assertIllegalTransitions errorCreatingMachine, illegalStates


  it 'tests Active state transitions', ->

    legalStates = ['Ending']
    illegalStates = [
      'ErrorCreating', 'ErrorLoading', 'Resuming', 'Active'
      'Loading', 'Prepared', 'NotStarted', 'Creating', 'Preparing'
    ]

    assertLegalTransitions activeMachine, legalStates
    assertIllegalTransitions activeMachine, illegalStates


  it 'tests Ending state transitions', ->

    legalStates = []
    illegalStates = [
      'ErrorCreating', 'ErrorLoading', 'Resuming', 'Active'
      'Loading', 'Prepared', 'NotStarted', 'Creating', 'Ending', 'Preparing'
    ]

    assertLegalTransitions endingMachine, legalStates
    assertIllegalTransitions endingMachine, illegalStates


assertLegalTransitions = (machineFactoryFn, states) ->
  states.forEach (state) ->
    machine = machineFactoryFn()
    machine.transition state
    expect(machine.state).to.equal state

assertIllegalTransitions = (machineFactoryFn, states) ->
  states.forEach (state) ->
    machine = machineFactoryFn()
    expect(-> machine.transition state).to.throw /illegal state transition/

newSimpleMachine = -> new CollabStateMachine

loadingMachine = -> newSimpleMachine()

resumingMachine = ->
  machine = new CollabStateMachine
  machine.transition 'Resuming'
  return machine

errorLoadingMachine = ->
  machine = new CollabStateMachine
  machine.transition 'ErrorLoading'
  return machine

notStartedMachine = ->
  machine = new CollabStateMachine
  machine.transition 'NotStarted'
  return machine

preparingMachine = ->
  machine = notStartedMachine()
  machine.transition 'Preparing'
  return machine

preparedMachine = ->
  machine = preparingMachine()
  machine.transition 'Prepared'
  return machine

creatingMachine = ->
  machine = preparedMachine()
  machine.transition 'Creating'
  return machine

errorCreatingMachine = ->
  machine = creatingMachine()
  machine.transition 'ErrorCreating'
  return machine

activeMachine = ->
  machine = resumingMachine()
  machine.transition 'Active'
  return machine

endingMachine = ->
  machine = activeMachine()
  machine.transition 'Ending'
  return machine

