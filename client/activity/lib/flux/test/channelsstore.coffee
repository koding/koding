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


