{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputSearchVisibilityStore = require 'activity/flux/stores/chatinput/chatinputsearchvisibilitystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputSearchVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputSearchVisibility : ChatInputSearchVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, { stateId, visible : yes }
      visible = @reactor.evaluate(['chatInputSearchVisibility']).get stateId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, { stateId, visible : no }
      visible = @reactor.evaluate(['chatInputSearchVisibility']).get stateId

      expect(visible).to.be.false

