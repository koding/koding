mock             = require '../../../../../../mocks/mockingjay'
expect           = require 'expect'
Reactor          = require 'app/flux/base/reactor'
immutable        = require 'immutable'
actionTypes      = require 'app/flux/environment/actiontypes'
OwnMachinesStore = require 'app/flux/environment/stores/ownmachinesstore'


ENV_DATA    = mock.envDataProvider.fetch.toReturnLoadDataWithOwnMachine()
{ machine } = ENV_DATA.own.first

describe 'OwnMachinesStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores ownMachines : OwnMachinesStore


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['ownMachines'])

      expect(store).toBe immutable.Map()


  describe '#load', ->

    it 'should set own machine id to store', ->

      @reactor.dispatch actionTypes.LOAD_USER_ENVIRONMENT_SUCCESS, ENV_DATA

      store = @reactor.evaluate(['ownMachines']).get machine._id

      expect(store).toExist()
