{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputChannelsSelectedIndexStore = require 'activity/flux/stores/chatinput/chatinputchannelsselectedindexstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'ChatInputChannelsSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputChannelsSelectedIndex : ChatInputChannelsSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 3

      @reactor.dispatch actionTypes.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputChannelsSelectedIndex']

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 3
      nextIndex = index + 1

      @reactor.dispatch actionTypes.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputChannelsSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actionTypes.MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX
      selectedIndex = @reactor.evaluate ['chatInputChannelsSelectedIndex']

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 3
      prevIndex = index - 1

      @reactor.dispatch actionTypes.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputChannelsSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actionTypes.MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX
      selectedIndex = @reactor.evaluate ['chatInputChannelsSelectedIndex']

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 3

      @reactor.dispatch actionTypes.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputChannelsSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actionTypes.RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX
      selectedIndex = @reactor.evaluate ['chatInputChannelsSelectedIndex']

      expect(selectedIndex).to.equal 0
