{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputUsersVisibilityStore = require 'activity/flux/stores/chatinput/chatinputusersvisibilitystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputUsersVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputUsersVisibility : ChatInputUsersVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_VISIBILITY, { stateId, visible : yes }
      visible = @reactor.evaluate(['chatInputUsersVisibility']).get stateId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_VISIBILITY, { stateId, visible : no }
      visible = @reactor.evaluate(['chatInputUsersVisibility']).get stateId

      expect(visible).to.be.false

