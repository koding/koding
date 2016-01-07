expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputValueStore = require 'activity/flux/chatinput/stores/valuestore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputValueStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputValue : ChatInputValueStore


  describe '#setValue', ->

    it 'sets value depending on channel', ->

      channelId  = 'test'
      stateId    = '123'
      testValue1 = 'qwerty'
      testValue2 = 'whoa!'

      @reactor.dispatch actions.SET_CHAT_INPUT_VALUE, { channelId, stateId, value : testValue1 }
      value = @reactor.evaluate(['chatInputValue']).getIn [channelId, stateId]

      expect(value).toEqual testValue1

      @reactor.dispatch actions.SET_CHAT_INPUT_VALUE, { channelId, stateId, value : testValue2 }
      value = @reactor.evaluate(['chatInputValue']).getIn [channelId, stateId]

      expect(value).toEqual testValue2
