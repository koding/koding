expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputSearchFlagsStore = require 'activity/flux/chatinput/stores/search/flagsstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputSearchFlagsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputSearchFlags : ChatInputSearchFlagsStore


  describe '#handleSearchBegin', ->

    it 'sets isLoading flag', ->

      stateId = '123'

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_BEGIN, { stateId }
      flags = @reactor.evaluate(['chatInputSearchFlags']).get stateId

      expect(flags.get 'isLoading').toBe yes


  describe '#handleSearchEnd', ->

    it 'unsets isLoading flag', ->

      stateId = '123'

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_BEGIN, { stateId }
      flags = @reactor.evaluate(['chatInputSearchFlags']).get stateId
      expect(flags.get 'isLoading').toBe yes

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_SUCCESS, { stateId }
      flags = @reactor.evaluate(['chatInputSearchFlags']).get stateId
      expect(flags.get 'isLoading').toBe no

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_BEGIN, { stateId }
      flags = @reactor.evaluate(['chatInputSearchFlags']).get stateId
      expect(flags.get 'isLoading').toBe yes

      @reactor.dispatch actions.CHAT_INPUT_SEARCH_FAIL, { stateId }
      flags = @reactor.evaluate(['chatInputSearchFlags']).get stateId
      expect(flags.get 'isLoading').toBe no
