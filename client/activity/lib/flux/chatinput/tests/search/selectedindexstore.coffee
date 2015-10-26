{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputSearchSelectedIndexStore = require 'activity/flux/chatinput/stores/search/selectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputSearchSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputSearchSelectedIndex : ChatInputSearchSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 3
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputSearchSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 3
      stateId = 'test'
      nextIndex = index + 1

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputSearchSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputSearchSelectedIndex']).get stateId

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 3
      stateId = 'test'
      prevIndex = index - 1

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputSearchSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputSearchSelectedIndex']).get stateId

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 3
      stateId = 'test'

      @reactor.dispatch actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputSearchSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputSearchSelectedIndex']).get stateId

      expect(selectedIndex).to.be.undefined

