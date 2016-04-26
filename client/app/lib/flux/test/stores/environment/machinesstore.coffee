mock            = require '../../../../../../mocks/mockingjay'
expect          = require 'expect'
Reactor         = require 'app/flux/base/reactor'
immutable       = require 'immutable'
actionTypes     = require 'app/flux/environment/actiontypes'
MachinesStore   = require 'app/flux/environment/stores/machinesstore'


machine   = mock.getMockImmutableMachine()
id        = machine.get '_id'
ENV_DATA  = mock.envDataProvider.fetch.toReturnLoadDataWithOwnMachine()


describe 'MachinesStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores { machines : MachinesStore }


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['machines'])

      expect(store).toBe immutable.Map()


  describe '#load', ->

    it 'should load environment data correctly', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()


  describe '#updateMachine', ->

    it 'should update status and percentage of machine correctly', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()

      event =
        percentage  : '79'
        status      : 'Building'

      @reactor.dispatch actionTypes.MACHINE_UPDATED, { id, event }

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()
      expect(store.getIn(['status', 'state'])).toBe event.status
      expect(store.get 'percentage').toBe event.percentage


    it 'should replace machine with new machine instance', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()

      newMachine = mock.getMockMachine()
      newMachine.label = 'new-machine'

      @reactor.dispatch actionTypes.MACHINE_UPDATED, { id, machine : newMachine }

      store = @reactor.evaluate(['machines']).get id

      expect(store.get 'label').toBe newMachine.label
      expect(store.get 'label').toNotBe machine.get 'label'


  describe '#acceptInvitation', ->

    it 'should mark isApproved as yes', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()

      @reactor.dispatch actionTypes.INVITATION_ACCEPTED, id

      store = @reactor.evaluate(['machines']).get id

      expect(store.get 'isApproved').toBeTruthy()


  describe '#setAlwaysOnBegin', ->

    it 'should set alwaysOn flag to specified value and save old alwaysOn flag', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA
      @reactor.dispatch actionTypes.SET_MACHINE_ALWAYS_ON_BEGIN, { id, state : yes }

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()
      expect(store.getIn [ 'meta', 'alwaysOn' ]).toBeTruthy()
      expect(store.getIn [ 'meta', '_alwaysOn' ]).toBeFalsy()


  describe '#setAlwaysOnSuccess', ->

    it 'should delete old alwaysOn flag', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA
      @reactor.dispatch actionTypes.SET_MACHINE_ALWAYS_ON_BEGIN, { id, state : yes }

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()
      expect(store.getIn [ 'meta', '_alwaysOn' ]).toBeFalsy()

      @reactor.dispatch actionTypes.SET_MACHINE_ALWAYS_ON_SUCCESS, { id }

      store = @reactor.evaluate(['machines']).get id
      expect(store.getIn [ 'meta', 'alwaysOn' ]).toBeTruthy()
      expect(store.getIn [ 'meta', '_alwaysOn' ]).toNotExist()


  describe '#setAlwaysOnFail', ->

    it 'should revert changes on alwaysOn flag', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA
      @reactor.dispatch actionTypes.SET_MACHINE_ALWAYS_ON_BEGIN, { id, state : yes }

      store = @reactor.evaluate(['machines']).get id

      expect(store).toExist()
      expect(store.getIn [ 'meta', 'alwaysOn' ]).toBeTruthy()

      @reactor.dispatch actionTypes.SET_MACHINE_ALWAYS_ON_FAIL, { id }

      store = @reactor.evaluate(['machines']).get id
      expect(store.getIn [ 'meta', 'alwaysOn' ]).toBeFalsy()
      expect(store.getIn [ 'meta', '_alwaysOn' ]).toNotExist()
