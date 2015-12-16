expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChatInputMentionsSelectedIndexStore = require 'activity/flux/chatinput/stores/mention/selectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputMentionsSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputMentionsSelectedIndex : ChatInputMentionsSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 1
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputMentionsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 1
      stateId = '123'
      nextIndex = index + 1

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputMentionsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_CHAT_INPUT_MENTIONS_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputMentionsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 1
      stateId = '123'
      prevIndex = index - 1

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputMentionsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index
      
      @reactor.dispatch actions.MOVE_TO_PREV_CHAT_INPUT_MENTIONS_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputMentionsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 1
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_MENTIONS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputMentionsSelectedIndex']).get stateId

      expect(selectedIndex).toEqual index

      @reactor.dispatch actions.RESET_CHAT_INPUT_MENTIONS_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputMentionsSelectedIndex']).get stateId

      expect(selectedIndex).toBe undefined

