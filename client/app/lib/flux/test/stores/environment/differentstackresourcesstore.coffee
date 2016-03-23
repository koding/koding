expect                        = require 'expect'
Reactor                       = require 'app/flux/base/reactor'
actionTypes                   = require 'app/flux/environment/actiontypes'
DifferentStackResourcesStore  = require 'app/flux/environment/stores/differentstackresourcesstore'


describe 'DifferentStackResourcesStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { differentStackResources : DifferentStackResourcesStore }


  describe '#getInitialState', ->

    it 'should be null', ->

      store = @reactor.evaluate(['differentStackResources'])

      expect(store).toBe null


  describe '#show', ->

    it 'should set yes to store', ->

      @reactor.dispatch actionTypes.GROUP_STACKS_INCONSISTENT

      store = @reactor.evaluate(['differentStackResources'])

      expect(store).toBe yes


  describe '#hide', ->

    it 'should set null to store', ->

      @reactor.dispatch actionTypes.GROUP_STACKS_CONSISTENT

      store = @reactor.evaluate(['differentStackResources'])

      expect(store).toBe null
