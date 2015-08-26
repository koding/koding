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

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, { visible : yes }
      visible = @reactor.evaluate ['chatInputSearchVisibility']

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_VISIBILITY, { visible : no }
      visible = @reactor.evaluate ['chatInputSearchVisibility']

      expect(visible).to.be.false

