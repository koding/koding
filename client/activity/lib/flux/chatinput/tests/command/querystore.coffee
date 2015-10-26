{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputCommandsQueryStore = require 'activity/flux/chatinput/stores/command/querystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputCommandsQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputCommandsQuery : ChatInputCommandsQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1  = '/s'
      query2  = '/invite'
      stateId = 'qwerty'

      @reactor.dispatch actions.SET_CHAT_INPUT_COMMANDS_QUERY, { stateId, query : query1 }
      query = @reactor.evaluate(['chatInputCommandsQuery']).get stateId

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CHAT_INPUT_COMMANDS_QUERY, { stateId, query: query2 }
      query = @reactor.evaluate(['chatInputCommandsQuery']).get stateId

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = '/s'
      stateId   = 'qwerty'

      @reactor.dispatch actions.SET_CHAT_INPUT_COMMANDS_QUERY, { stateId, query : testQuery }
      query = @reactor.evaluate(['chatInputCommandsQuery']).get stateId

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_CHAT_INPUT_COMMANDS_QUERY, { stateId }
      query = @reactor.evaluate(['chatInputCommandsQuery']).get stateId

      expect(query).to.be.undefined

