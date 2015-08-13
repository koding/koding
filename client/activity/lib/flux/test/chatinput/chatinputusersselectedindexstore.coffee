{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChatInputUsersSelectedIndexStore = require 'activity/flux/stores/chatinput/chatinputusersselectedindexstore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChatInputUsersSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputUsersSelectedIndex : ChatInputUsersSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputUsersSelectedIndex']

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 1
      nextIndex = index + 1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputUsersSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX
      selectedIndex = @reactor.evaluate ['chatInputUsersSelectedIndex']

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 1
      prevIndex = index - 1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputUsersSelectedIndex']

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX
      selectedIndex = @reactor.evaluate ['chatInputUsersSelectedIndex']

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['chatInputUsersSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_CHAT_INPUT_USERS_SELECTED_INDEX
      selectedIndex = @reactor.evaluate ['chatInputUsersSelectedIndex']

      expect(selectedIndex).to.equal 0
