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

      initiatorId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_VISIBILITY, { initiatorId, visible : yes }
      visible = @reactor.evaluate(['chatInputUsersVisibility']).get initiatorId

      expect(visible).to.be.true

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_VISIBILITY, { initiatorId, visible : no }
      visible = @reactor.evaluate(['chatInputUsersVisibility']).get initiatorId

      expect(visible).to.be.false

