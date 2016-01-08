expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputChannelsQueryStore = require 'activity/flux/chatinput/stores/channel/querystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputChannelsQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputChannelsQuery : ChatInputChannelsQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1      = 'koding'
      query2      = 'tests'
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_QUERY, { stateId, query : query1 }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get stateId

      expect(query).toEqual query1

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_QUERY, { stateId, query: query2 }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get stateId

      expect(query).toEqual query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery   = 'koding'
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_QUERY, { stateId, query : testQuery }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get stateId

      expect(query).toEqual testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_CHANNELS_QUERY, { stateId }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get stateId

      expect(query).toBe undefined
