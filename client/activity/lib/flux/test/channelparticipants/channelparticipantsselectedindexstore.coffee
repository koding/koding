{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChannelParticipantsSelectedIndexStore = require 'activity/flux/stores/channelparticipants/channelparticipantsselectedindexstore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChannelParticipantsSelectedIndexStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores channelParticipantsSelectedIndex : ChannelParticipantsSelectedIndexStore


  describe '#setIndex', ->

    it 'sets selected index', ->

      index = 3

      @reactor.dispatch actions.SET_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['channelParticipantsSelectedIndex']

      expect(selectedIndex).to.equal index


  describe '#moveToNextIndex', ->

    it 'moves to next index', ->

      index = 3
      nextIndex = index + 1

      @reactor.dispatch actions.SET_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['channelParticipantsSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.MOVE_TO_NEXT_CHANNEL_PARTICIPANT_INDEX
      selectedIndex = @reactor.evaluate ['channelParticipantsSelectedIndex']

      expect(selectedIndex).to.equal nextIndex


  describe '#moveToPrevIndex', ->

    it 'moves to prev index', ->

      index = 3
      prevIndex = index - 1

      @reactor.dispatch actions.SET_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['channelParticipantsSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.MOVE_TO_PREV_CHANNEL_PARTICIPANT_INDEX
      selectedIndex = @reactor.evaluate ['channelParticipantsSelectedIndex']

      expect(selectedIndex).to.equal prevIndex


  describe '#resetIndex', ->

    it 'resets selected index', ->

      index = 3

      @reactor.dispatch actions.SET_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }
      selectedIndex = @reactor.evaluate ['channelParticipantsSelectedIndex']

      expect(selectedIndex).to.equal index

      @reactor.dispatch actions.RESET_CHANNEL_PARTICIPANTS_SELECTED_INDEX
      selectedIndex = @reactor.evaluate ['channelParticipantsSelectedIndex']

      expect(selectedIndex).to.equal 0

