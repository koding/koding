expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputChannelsSelectedIndexStore = require 'activity/flux/chatinput/stores/channel/selectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputChannelsSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputChannelsSelectedIndex : ChatInputChannelsSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 3
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputChannelsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 3
      nextIndex = index + 1
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { index, stateId }
      selectedIndex = @reactor.evaluate(['chatInputChannelsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputChannelsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 3
      prevIndex = index - 1
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { index, stateId }
      selectedIndex = @reactor.evaluate(['chatInputChannelsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index
      
      @reactor.dispatch actions.MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputChannelsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 3
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { index, stateId }
      selectedIndex = @reactor.evaluate(['chatInputChannelsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index

      @reactor.dispatch actions.RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputChannelsSelectedIndex']).get stateId

      expect(selectedIndex).toBe undefined

