expect = require 'expect'

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

    expect(machine.states['Loading']).toExist()


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
      expect(flags.loading).toEqual yes

      model.machine.transition 'Activating'
      expect(flags.activating).toEqual yes

      model.machine.transition 'Active'
      expect(flags.active).toEqual yes

      model.machine.transition 'Terminating'
      expect(flags.terminating).toEqual yes

      model.machine.transition 'Terminated'
      expect(flags.terminated).toEqual yes


  describe '#transition', ->

    it "only transitions if only it's in the transitions array", ->

      machine = new FooMachine

      expect(machine.state).toEqual 'Loading'
      # expect(-> machine.transition 'Terminating').to.throw /illegal/
      expect(machine.state).toEqual 'Loading'

      machine.transition 'Activating'
      expect(machine.state).toEqual 'Activating'

      # expect(-> machine.transition 'Terminated').to.throw /illegal/
      expect(machine.state).toEqual 'Activating'



class KDObject

  constructor: (options = {}) ->
    @options = options

  bound: (fnName) -> return this[fnName].bind this
