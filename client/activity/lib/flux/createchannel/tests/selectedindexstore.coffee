expect = require 'expect'

Reactor = require 'app/flux/base/reactor'
actions = require 'activity/flux/createchannel/actions/actiontypes'
SelectedIndexStore = require 'activity/flux/createchannel/stores/selectedindexstore'

describe 'CreateNewChannelParticipantsSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores selectedIndex : SelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 3

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate(['selectedIndex'])

      expect(selectedIndex).toEqual index


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 3
      resetIndex = 0

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate(['selectedIndex'])

      expect(selectedIndex).toEqual index

      @reactor.dispatch actions.RESET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX
      selectedIndex = @reactor.evaluate(['selectedIndex'])

      expect(selectedIndex).toEqual 0


  describe '#moveToNextIndex', ->

    it 'moves to next index', ->

      index = 3
      nextIndex = index + 1

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate(['selectedIndex'])

      expect(selectedIndex).toEqual index

      @reactor.dispatch actions.MOVE_TO_NEXT_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX
      selectedIndex = @reactor.evaluate(['selectedIndex'])

      expect(selectedIndex).toEqual nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 3
      prevIndex = index - 1

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate(['selectedIndex'])

      expect(selectedIndex).toEqual index

      @reactor.dispatch actions.MOVE_TO_PREV_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX
      selectedIndex = @reactor.evaluate(['selectedIndex'])

      expect(selectedIndex).toEqual prevIndex


