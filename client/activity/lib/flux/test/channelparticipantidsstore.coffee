{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

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

      expect(storeState.foo).to.eql {}


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

      expect(storeState.qux).to.eql {'foo', 'bar'}


  describe '#handleLoadSuccess', ->

    it 'adds followed channel id to list when its loaded', ->

      @reactor.dispatch actions.LOAD_CHANNEL_PARTICIPANT_SUCCESS, {
        channelId: 'foo', userId: 'bar'
      }

      storeState = @reactor.evaluateToJS [ChannelParticipantIdsStore.getterPath]

      expect(storeState.foo).to.eql {'bar'}


