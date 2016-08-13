expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

ChannelParticipantIdsStore = require '../stores/channelparticipantidsstore'
actions = require '../actions/actiontypes'

describe 'ChannelParticipantIdsStore', ->

  before ->
    @reactor = new Reactor
    @reactor.registerStores [ChannelParticipantIdsStore]

  beforeEach ->
    @reactor.reset()

  describe '#handleChannelLoad', ->

    it 'initializes an empty channel participants container on channel load', ->

      channel = { id: 'foo' }
      @reactor.dispatch actions.LOAD_CHANNEL_SUCCESS, { channel }

      storeState = @reactor.evaluateToJS [ChannelParticipantIdsStore.getterPath]

      expect(storeState.foo).toEqual {}


  describe '#handleLoadBegin', ->

    it 'adds given participantsPreview ids to channel participants container', ->

      participantsPreview = [
        constructorName: 'JAccount'
        _id: 'foo'
      ,
        constructorName: 'JAccount'
        _id: 'bar'
      ]

      @reactor.dispatch actions.LOAD_CHANNEL_PARTICIPANTS_BEGIN, {
        participantsPreview, channelId: 'qux'
      }

      storeState = @reactor.evaluateToJS [ChannelParticipantIdsStore.getterPath]

      expect(storeState.qux).toEqual { 'foo', 'bar' }


  describe '#handleLoadSuccess', ->

    it 'adds followed channel id to list when its loaded', ->

      @reactor.dispatch actions.LOAD_CHANNEL_PARTICIPANT_SUCCESS, {
        channelId: 'foo', userId: 'bar'
      }

      storeState = @reactor.evaluateToJS [ChannelParticipantIdsStore.getterPath]

      expect(storeState.foo).toEqual { 'bar' }


  describe '#handleFollowChannelSuccess', ->

    it 'adds given accountId to the channel of ChannelParticipantIdsStore when follow channel action succeed', ->

      @reactor.dispatch actions.FOLLOW_CHANNEL_SUCCESS, {
        channelId: 'foo', accountId: 'bar'
      }

      storeState = @reactor.evaluateToJS [ChannelParticipantIdsStore.getterPath]

      expect(storeState.foo).toEqual { 'bar' }


  describe '#handleUnfollowChannelSuccess', ->

    it 'removes given accountId to the channel of ChannelParticipantIdsStore when unfollow channel action succeed', ->

      @reactor.dispatch actions.FOLLOW_CHANNEL_SUCCESS, {
        channelId: 'testchannel_1', accountId: 'testAccount_1'
      }

      @reactor.dispatch actions.FOLLOW_CHANNEL_SUCCESS, {
        channelId: 'testchannel_2', accountId: 'testAccount_2'
      }

      @reactor.dispatch actions.UNFOLLOW_CHANNEL_SUCCESS, {
        channelId: 'testchannel_1', accountId: 'testAccount_1'
      }

      storeState = @reactor.evaluateToJS [ChannelParticipantIdsStore.getterPath]

      expect(storeState.testchannel_2).toEqual { 'testAccount_2' }
      expect(storeState.testchannel_1).toEqual {}
