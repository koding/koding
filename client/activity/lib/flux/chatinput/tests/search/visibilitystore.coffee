expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputSearchVisibilityStore = require 'activity/flux/chatinput/stores/search/visibilitystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputSearchVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputSearchVisibility : ChatInputSearchVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, { stateId, visible : yes }
      visible = @reactor.evaluate(['chatInputSearchVisibility']).get stateId

      expect(visible).toBe yes

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, { stateId, visible : no }
      visible = @reactor.evaluate(['chatInputSearchVisibility']).get stateId

      expect(visible).toBe no

