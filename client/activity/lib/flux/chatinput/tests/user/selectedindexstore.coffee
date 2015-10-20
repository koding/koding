{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChatInputUsersSelectedIndexStore = require 'activity/flux/chatinput/stores/user/selectedindexstore'
actions = require 'activity/flux/chatinput/actions/actiontypes'

describe 'ChatInputUsersSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores chatInputUsersSelectedIndex : ChatInputUsersSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 1
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputUsersSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

  	it 'moves to next index', ->

      index = 1
      stateId = '123'
      nextIndex = index + 1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputUsersSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputUsersSelectedIndex']).get stateId

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 1
      stateId = '123'
      prevIndex = index - 1

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputUsersSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index
      
      @reactor.dispatch actions.MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputUsersSelectedIndex']).get stateId

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 1
      stateId = '123'

      @reactor.dispatch actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX, { stateId, index }
      selectedIndex = @reactor.evaluate(['chatInputUsersSelectedIndex']).get stateId

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_CHAT_INPUT_USERS_SELECTED_INDEX, { stateId }
      selectedIndex = @reactor.evaluate(['chatInputUsersSelectedIndex']).get stateId

      expect(selectedIndex).to.be.undefined

