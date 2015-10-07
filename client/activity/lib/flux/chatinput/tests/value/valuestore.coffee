{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputValueStore = require 'activity/flux/chatinput/stores/valuestore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputValueStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputValue : ChatInputValueStore


  describe '#setValue', ->

    it 'sets value depending on channel', ->

      channelId  = 'test'
      testValue1 = 'qwerty'
      testValue2 = 'whoa!'

      @reactor.dispatch actions.SET_CHAT_INPUT_VALUE, { channelId, value : testValue1 }
      value = @reactor.evaluate(['chatInputValue']).get channelId

      expect(value).to.equal testValue1

      @reactor.dispatch actions.SET_CHAT_INPUT_VALUE, { channelId, value : testValue2 }
      value = @reactor.evaluate(['chatInputValue']).get channelId

      expect(value).to.equal testValue2

