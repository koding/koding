{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputChannelsVisibilityStore = require 'activity/flux/stores/chatinput/chatinputchannelsvisibilitystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputChannelsVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputChannelsVisibility : ChatInputChannelsVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_VISIBILITY, { stateId, visible : yes }
      visibility = @reactor.evaluate(['chatInputChannelsVisibility']).get stateId

      expect(visibility).to.be.true

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_VISIBILITY, { stateId, visible : no }
      visibility = @reactor.evaluate(['chatInputChannelsVisibility']).get stateId

      expect(visibility).to.be.false

