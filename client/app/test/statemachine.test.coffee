{ expect } = require 'chai'

StateMachine = require '../lib/statemachine'

describe 'StateMachine', ->

  class FooMachine extends StateMachine
    states: [
      'Loading'
      'Activating'
      'Active'
      'Terminating'
      'Terminated'
    ]
    transitions:
      Loading     : ['Activating', 'Terminated']
      Activating  : ['Active']
      Active      : ['Terminating']
      Terminating : ['Terminated']
      # Terminated  : null

  it 'reads states from prototype', ->

    machine = new FooMachine

    expect(machine.states['Loading']).to.be.ok


  it 'reads stateHandlers from options to connect state transitions with outside', ->

    flags = {}
    class FooModel extends KDObject
      constructor: (options = {}) ->
        @machine = new FooMachine
          stateHandlers:
            Loading     : @bound 'onFooLoading'
            Activating  : @bound 'onFooActivating'
            Active      : @bound 'onFooActive'
            Terminating : @bound 'onFooTerminating'
            Terminated  : @bound 'onFooTerminated'
      onFooLoading     : -> flags['loading'] = yes
      onFooActivating  : -> flags['activating'] = yes
      onFooActive      : -> flags['active'] = yes
      onFooTerminating : -> flags['terminating'] = yes
      onFooTerminated  : -> flags['terminated'] = yes

      model = new FooModel
      expect(flags.loading).to.equal yes

      model.machine.transition 'Activating'
      expect(flags.activating).to.equal yes

      model.machine.transition 'Active'
      expect(flags.active).to.equal yes

      model.machine.transition 'Terminating'
      expect(flags.terminating).to.equal yes

      model.machine.transition 'Terminated'
      expect(flags.terminated).to.equal yes


  describe '#transition', ->

    it "only transitions if only it's in the transitions array", ->

      machine = new FooMachine

      expect(machine.state).to.equal 'Loading'
      # expect(-> machine.transition 'Terminating').to.throw /illegal/
      expect(machine.state).to.equal 'Loading'

      machine.transition 'Activating'
      expect(machine.state).to.equal 'Activating'

      # expect(-> machine.transition 'Terminated').to.throw /illegal/
      expect(machine.state).to.equal 'Activating'



class KDObject

  constructor: (options = {}) ->
    @options = options

  bound: (fnName) -> return this[fnName].bind this


