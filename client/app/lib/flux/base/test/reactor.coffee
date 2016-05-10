expect = require 'expect'

Store = require '../store'
Reactor = require '../reactor'

describe 'KodingFluxReactor', ->

  describe '#registerStores', ->

    it 'registers stores as classes rather than instances', ->

      reactor = new Reactor

      flag = no
      class FooStore extends Store
        initialize: ->
          @on 'test', (state, { foo }) -> flag = foo


      reactor.registerStores { foo: FooStore }

      reactor.dispatch 'test', { foo: 'test passed' }

      expect(flag).toEqual 'test passed'
