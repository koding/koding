{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputChannelsQueryStore = require 'activity/flux/stores/chatinput/chatinputchannelsquerystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputChannelsQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputChannelsQuery : ChatInputChannelsQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1      = 'koding'
      query2      = 'tests'
      initiatorId = 'qwerty'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_QUERY, { initiatorId, query : query1 }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get initiatorId

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_QUERY, { initiatorId, query: query2 }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get initiatorId

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery   = 'koding'
      initiatorId = 'qwerty'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_QUERY, { initiatorId, query : testQuery }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get initiatorId

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_CHANNELS_QUERY, { initiatorId }
      query = @reactor.evaluate(['chatInputChannelsQuery']).get initiatorId

      expect(query).to.be.undefined

