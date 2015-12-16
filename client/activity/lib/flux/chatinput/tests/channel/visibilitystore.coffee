expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputChannelsVisibilityStore = require 'activity/flux/chatinput/stores/channel/visibilitystore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputChannelsVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputChannelsVisibility : ChatInputChannelsVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_VISIBILITY, { stateId, visible : yes }
      visibility = @reactor.evaluate(['chatInputChannelsVisibility']).get stateId

      expect(visibility).toBe yes

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_VISIBILITY, { stateId, visible : no }
      visibility = @reactor.evaluate(['chatInputChannelsVisibility']).get stateId

      expect(visibility).toBe no

