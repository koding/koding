expect = require 'expect'

Reactor = require 'app/flux/base/reactor'
ChatInputValueStore = require 'activity/flux/chatinput/stores/valuestore'
SelectedChannelThreadIdStore = require 'activity/flux/stores/selectedchannelthreadidstore'
ChatInputFlux = require 'activity/flux/chatinput'
ActivityActions = require 'activity/flux/actions/actiontypes'
ChatInputActions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputValueGetter', ->

  beforeEach ->

    @reactor = new Reactor()
    stores = {}
    stores[ChatInputValueStore.getterPath] = ChatInputValueStore
    stores[SelectedChannelThreadIdStore.getterPath] = SelectedChannelThreadIdStore
    @reactor.registerStores stores


  describe '#currentValue', ->

    channelId1   = 'channel1'
    channelId2   = 'channel2'
    stateId      = '123'
    value1       = '12345'
    value2       = 'qwerty'
    emptyChannel = 'channel3'
    { getters }  = ChatInputFlux

    it 'gets value depending on the current channel id', ->

      @reactor.dispatch ChatInputActions.SET_CHAT_INPUT_VALUE, { channelId : channelId1, stateId, value : value1 }
      @reactor.dispatch ChatInputActions.SET_CHAT_INPUT_VALUE, { channelId : channelId2, stateId, value : value2 }

      @reactor.dispatch ActivityActions.SET_SELECTED_CHANNEL_THREAD, { channelId : channelId1 }

      value = @reactor.evaluate getters.currentValue stateId
      expect(value).toEqual value1

      @reactor.dispatch ActivityActions.SET_SELECTED_CHANNEL_THREAD, { channelId : channelId2 }

      value = @reactor.evaluate getters.currentValue stateId
      expect(value).toEqual value2

      @reactor.dispatch ActivityActions.SET_SELECTED_CHANNEL_THREAD, { channelId : emptyChannel }

      value = @reactor.evaluate getters.currentValue stateId
      expect(value).toEqual ''
