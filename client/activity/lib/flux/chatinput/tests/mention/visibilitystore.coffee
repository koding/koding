{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputMentionsVisibilityStore = require 'activity/flux/chatinput/stores/mention/visibilitystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputMentionsVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputMentionsVisibility : ChatInputMentionsVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_VISIBILITY, { stateId, visible : yes }
      visible = @reactor.evaluate(['chatInputMentionsVisibility']).get stateId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_VISIBILITY, { stateId, visible : no }
      visible = @reactor.evaluate(['chatInputMentionsVisibility']).get stateId

      expect(visible).to.be.false

