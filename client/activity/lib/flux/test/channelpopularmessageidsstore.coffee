expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChannelPopularMessageIdsStore = require '../stores/channelpopularmessageidsstore'
actionTypes = require '../actions/actiontypes'

describe 'ChannelPopularMessageIdsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ChannelPopularMessageIdsStore]

  describe '#handleLoadSuccess', ->

    it 'adds followed channel id to list when its loaded', ->

      @reactor.dispatch actionTypes.LOAD_POPULAR_MESSAGE_SUCCESS, {
        channelId: 'foo', message: { id: 'bar' }
      }

      @reactor.dispatch actionTypes.LOAD_POPULAR_MESSAGE_SUCCESS, {
        channelId: 'baz', message: { id: 'qux' }
      }

      storeState = @reactor.evaluateToJS ['ChannelPopularMessageIdsStore']

      expect(storeState.foo['bar']).toEqual 'bar'
      expect(storeState.baz['qux']).toEqual 'qux'
