{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

ChannelsStore = require '../stores/channelsstore'
actionTypes = require '../actions/actiontypes'

describe 'ChannelsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [ChannelsStore]

  describe 'handleLoadChannelSuccess', ->

    it 'loads channels', ->

      mockPublicChannel = { id: 'foo', name: 'foo', typeConstant: 'topic' }
      mockPrivateChannel = { id: 'bar', purpose: 'bar', typeConstant: 'privatemessage' }

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, {
        channel: mockPublicChannel
      }

      storeState = @reactor.evaluateToJS ['ChannelsStore']

      expect(storeState.foo).to.eql mockPublicChannel

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, {
        channel: mockPrivateChannel
      }

      expect(storeState.foo).to.eql mockPublicChannel


