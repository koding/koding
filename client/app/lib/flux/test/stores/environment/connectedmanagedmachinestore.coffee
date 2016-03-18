mock                          = require '../../../../../../mocks/mockingjay'
expect                        = require 'expect'
Reactor                       = require 'app/flux/base/reactor'
immutable                     = require 'immutable'
actionTypes                   = require 'app/flux/environment/actiontypes'
ConnectedManagedMachineStore  = require 'app/flux/environment/stores/connectedmanagedmachinestore'


id    = mock.getMockMachine()._id
info  =
  providerName : 'DigitalOcean'


describe 'ConnectedManagedMachineStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { connectedManagedMachine : ConnectedManagedMachineStore }


  describe '#getInitialState', ->

    it 'should be an immutable map', ->

      store = @reactor.evaluate(['connectedManagedMachine'])

      expect(store).toBe immutable.Map()


  describe '#add', ->

    it 'should add machine id with provider name', ->

      @reactor.dispatch actionTypes.SHOW_MANAGED_MACHINE_ADDED_MODAL, { info, id }

      store = @reactor.evaluate(['connectedManagedMachine']).get id

      expect(store).toExist()


    it 'should add a DigitalOcean machine', ->

      @reactor.dispatch actionTypes.SHOW_MANAGED_MACHINE_ADDED_MODAL, { info, id }

      store = @reactor.evaluate(['connectedManagedMachine']).get id

      expect(store.providerName).toBe 'DigitalOcean'


  describe '#remove', ->

    it 'should remove a connected managed machine', ->

      @reactor.dispatch actionTypes.SHOW_MANAGED_MACHINE_ADDED_MODAL, { info, id }

      store = @reactor.evaluate(['connectedManagedMachine']).get id

      expect(store).toExist()

      @reactor.dispatch actionTypes.HIDE_MANAGED_MACHINE_ADDED_MODAL, { id }

      store = @reactor.evaluate(['connectedManagedMachine']).get id

      expect(store).toBe undefined
