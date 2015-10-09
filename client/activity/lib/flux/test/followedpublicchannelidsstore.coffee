{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

FollowedPublicChannelIdsStore = require '../stores/followedpublicchannelidsstore'
actionTypes = require '../actions/actiontypes'

describe 'FollowedPublicChannelIdsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [FollowedPublicChannelIdsStore]

  describe '#handleLoadChannelSuccess', ->

    it 'adds followed channel id to list when its loaded', ->

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, {
        channel: { id: 'foo' }
      }

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, {
        channel: { id: 'bar' }
      }

      storeState = @reactor.evaluateToJS ['FollowedPublicChannelIdsStore']

      expect(storeState.foo).to.eql 'foo'
      expect(storeState.bar).to.eql 'bar'
