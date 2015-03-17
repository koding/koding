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
    expect(states['PreCreated']).to.be.ok
    expect(states['Creating']).to.be.ok
    expect(states['ErrorCreating']).to.be.ok
    expect(states['Active']).to.be.ok
    expect(states['Ending']).to.be.ok


  it 'tests Loading state transitions', ->

    machine = newSimpleMachine()

    expect(machine.state).to.equal 'Loading'

    # illegal states
    expect(-> machine.transition 'Active').to.throw /illegal state transition/
    expect(-> machine.transition 'PreCreated').to.throw /illegal state transition/
    expect(-> machine.transition 'Creating').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/

    # legal states
    machine = newSimpleMachine()
    machine.transition 'NotStarted'
    expect(machine.state).to.equal 'NotStarted'

    machine = newSimpleMachine()
    machine.transition 'ErrorLoading'
    expect(machine.state).to.equal 'ErrorLoading'

    machine = newSimpleMachine()
    machine.transition 'Resuming'
    expect(machine.state).to.equal 'Resuming'


  it 'tests Resuming state transitions', ->

    machine = resumingMachine()
    machine.transition 'Active'
    expect(machine.state).to.equal 'Active'

    # illegal states
    machine = resumingMachine()
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/
    expect(-> machine.transition 'NotStarted').to.throw /illegal state transition/
    expect(-> machine.transition 'PreCreated').to.throw /illegal state transition/
    expect(-> machine.transition 'Creating').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/


  it 'tests ErrorLoading state transitions', ->

    machine = errorLoadingMachine()
    machine.transition 'Loading'
    expect(machine.state).to.equal 'Loading'

    # illegal states
    machine = errorLoadingMachine()
    expect(-> machine.transition 'NotStarted').to.throw /illegal state transition/
    expect(-> machine.transition 'PreCreated').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'Creating').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/
    expect(-> machine.transition 'Active').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/


  it 'tests NotStarted state transitions', ->

    machine = notStartedMachine()
    machine.transition 'PreCreated'
    expect(machine.state).to.equal 'PreCreated'

    # illegal states
    machine = notStartedMachine()
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'NotStarted').to.throw /illegal state transition/
    expect(-> machine.transition 'Creating').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/
    expect(-> machine.transition 'Active').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/


  it 'tests PreCreated state transitions', ->

    machine = preCreatedMachine()
    machine.transition 'Creating'
    expect(machine.state).to.equal 'Creating'

    # illegal states
    machine = preCreatedMachine()
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'NotStarted').to.throw /illegal state transition/
    expect(-> machine.transition 'PreCreated').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/
    expect(-> machine.transition 'Active').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/


  it 'tests Creating state transitions', ->

    machine = creatingMachine()
    machine.transition 'ErrorCreating'
    expect(machine.state).to.equal 'ErrorCreating'

    # illegal states
    machine = creatingMachine()
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'NotStarted').to.throw /illegal state transition/
    expect(-> machine.transition 'PreCreated').to.throw /illegal state transition/
    expect(-> machine.transition 'Creating').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/
    expect(-> machine.transition 'Active').to.throw /illegal state transition/


  it 'tests ErrorCreating state transitions', ->

    machine = errorCreatingMachine()
    machine.transition 'NotStarted'
    expect(machine.state).to.equal 'NotStarted'

    machine = errorCreatingMachine()
    machine.transition 'Creating'
    expect(machine.state).to.equal 'Creating'

    # illegal states
    machine = errorCreatingMachine()
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'PreCreated').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/
    expect(-> machine.transition 'Active').to.throw /illegal state transition/


  it 'tests Active state transitions', ->

    machine = activeMachine()
    machine.transition 'Ending'
    expect(machine.state).to.equal 'Ending'

    # illegal states
    machine = activeMachine()
    expect(-> machine.transition 'Creating').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'NotStarted').to.throw /illegal state transition/
    expect(-> machine.transition 'Active').to.throw /illegal state transition/


  it 'tests Ending state transitions', ->

    # illegal states
    machine = endingMachine()
    expect(-> machine.transition 'Creating').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorCreating').to.throw /illegal state transition/
    expect(-> machine.transition 'Loading').to.throw /illegal state transition/
    expect(-> machine.transition 'Resuming').to.throw /illegal state transition/
    expect(-> machine.transition 'ErrorLoading').to.throw /illegal state transition/
    expect(-> machine.transition 'NotStarted').to.throw /illegal state transition/
    expect(-> machine.transition 'PreCreated').to.throw /illegal state transition/
    expect(-> machine.transition 'Active').to.throw /illegal state transition/
    expect(-> machine.transition 'Ending').to.throw /illegal state transition/


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

preCreatedMachine = ->
  machine = notStartedMachine()
  machine.transition 'PreCreated'
  return machine

creatingMachine = ->
  machine = preCreatedMachine()
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
