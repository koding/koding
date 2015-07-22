{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChannelsStore = require '../stores/channelsstore'
actionTypes = require '../actions/actiontypes'

MessageCollectionHelpers = require '../helpers/messagecollection'

describe 'ChannelsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ChannelsStore]

  afterEach -> @reactor.reset()

  describe 'handleLoadChannelSuccess', ->

    it 'listens to regular load channel success', ->

      mockChannel = { id: 'public', name: 'public', typeConstant: 'group'}

      @reactor.dispatch actionTypes.LOAD_CHANNEL_SUCCESS, {
        channel: mockChannel
      }

      storeState = @reactor.evaluateToJS ['ChannelsStore']

      expect(storeState.public).to.eql mockChannel


    it 'loads channel when a private followed channel is loaded', ->

      mockPrivateChannel = { id: 'bar', purpose: 'bar', typeConstant: 'privatemessage' }

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, {
        channel: mockPrivateChannel
      }

      storeState = @reactor.evaluateToJS ['ChannelsStore']

      expect(storeState.bar).to.eql mockPrivateChannel


    it 'loads channel when a public followed channel is loaded', ->

      mockPublicChannel = { id: 'foo', name: 'foo', typeConstant: 'topic' }

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, {
        channel: mockPublicChannel
      }

      storeState = @reactor.evaluateToJS ['ChannelsStore']

      expect(storeState.foo).to.eql mockPublicChannel


  describe 'create message actions', ->

    it 'initializes a fake channel if there is not a channel instance before', ->

      channels = @reactor.evaluateToJS ['ChannelsStore']

      expect(Object.keys(channels).length).to.eql 0

      channelId = '123'

      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId, message: MessageCollectionHelpers.createFakeMessage '321', 'text'
      }

      channels = @reactor.evaluateToJS ['ChannelsStore']

      expect(channels[channelId]).to.be.ok
      expect(channels[channelId]['__fake']).to.be.ok


    it 'replaces fake channel with real one on create success', ->

      mockChannel = { id: '123', name: 'awesome' }

      # insert mock channel as fake into store first.
      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: mockChannel.id
      }

      channels = @reactor.evaluateToJS ['ChannelsStore']
      channel  = channels[mockChannel.id]

      expect(channel).to.eql { id: mockChannel.id, __fake: yes }

      @reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId: mockChannel.id, channel: mockChannel
      }

      channels = @reactor.evaluateToJS ['ChannelsStore']
      channel = channels[mockChannel.id]

      expect(channel).to.eql mockChannel


    it 'doesnt override channel when beginning creating a message', ->

      mockChannel = { id: '123', name: 'awesome' }

      # insert mock channel as fake into store first.
      @reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId: mockChannel.id, channel: mockChannel
      }

      # send a begin action after a success message is sent, which means that
      # there will be a channel in the store, so it shouldn't override.
      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: mockChannel.id
      }

      channels = @reactor.evaluateToJS ['ChannelsStore']
      channel = channels[mockChannel.id]

      # trying to see that if the mockChannel will
      # be replaced with {id, __fake: yes}
      expect(channel).to.eql mockChannel


    it 'removes a fake channel on create message fail if channel is fake', ->

      mockChannel = { id: '123', name: 'awesome' }

      # insert mock channel as fake into store first.
      @reactor.dispatch actionTypes.CREATE_MESSAGE_BEGIN, {
        channelId: mockChannel.id
      }

      channels = @reactor.evaluateToJS ['ChannelsStore']
      channel  = channels[mockChannel.id]

      expect(channel).to.eql { id: mockChannel.id, __fake: yes }

      # we are testing to see if this action will remove the fake channel
      # created above.
      @reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, {
        channelId: mockChannel.id
      }

      channels = @reactor.evaluateToJS ['ChannelsStore']
      channel = channels[mockChannel.id]

      expect(channel).to.be.undefined


    it 'doesnt remove channel if it is not fake on create message fail', ->

      mockChannel = { id: '123', name: 'awesome' }

      # insert mock channel as fake into store first.
      @reactor.dispatch actionTypes.CREATE_MESSAGE_SUCCESS, {
        channelId: mockChannel.id, channel: mockChannel
      }

      # dispatch a fail action to see if it removes a channel that is not fake.
      @reactor.dispatch actionTypes.CREATE_MESSAGE_FAIL, {
        channelId: mockChannel.id
      }

      channels = @reactor.evaluateToJS ['ChannelsStore']
      channel = channels[mockChannel.id]

      # trying to see that if the mockChannel will
      # be replaced with {id, __fake: yes}
      expect(channel).to.eql mockChannel


