{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputCommandsVisibilityStore = require 'activity/flux/chatinput/stores/command/visibilitystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputCommandsVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputCommandsVisibility : ChatInputCommandsVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_COMMANDS_VISIBILITY, { stateId, visible : yes }
      visibility = @reactor.evaluate(['chatInputCommandsVisibility']).get stateId

      expect(visibility).to.be.true

      @reactor.dispatch actions.SET_CHAT_INPUT_COMMANDS_VISIBILITY, { stateId, visible : no }
      visibility = @reactor.evaluate(['chatInputCommandsVisibility']).get stateId

      expect(visibility).to.be.false

