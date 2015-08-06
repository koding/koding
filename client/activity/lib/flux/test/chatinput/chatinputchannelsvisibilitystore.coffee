{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputChannelsVisibilityStore = require 'activity/flux/stores/chatinput/chatinputchannelsvisibilitystore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'ChatInputChannelsVisibilityStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputChannelsVisibility : ChatInputChannelsVisibilityStore


  describe '#setVisibility', ->

    it 'sets visibility', ->

      @reactor.dispatch actionTypes.SET_CHAT_INPUT_CHANNELS_VISIBILITY, { visible : yes }
      visible = @reactor.evaluate ['chatInputChannelsVisibility']

      expect(visible).to.be.true

      @reactor.dispatch actionTypes.SET_CHAT_INPUT_CHANNELS_VISIBILITY, { visible : no }
      visible = @reactor.evaluate ['chatInputChannelsVisibility']

      expect(visible).to.be.false
