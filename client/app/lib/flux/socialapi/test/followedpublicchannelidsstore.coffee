expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

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

      expect(storeState.foo).toEqual 'foo'
      expect(storeState.bar).toEqual 'bar'


  describe '#handleFollowChannelSuccess', ->

    it 'adds followed channelId to list when its followed', ->

      @reactor.dispatch actionTypes.FOLLOW_CHANNEL_SUCCESS, { channelId: 'foo' }
      @reactor.dispatch actionTypes.FOLLOW_CHANNEL_SUCCESS, { channelId: 'bar' }

      storeState = @reactor.evaluateToJS ['FollowedPublicChannelIdsStore']

      expect(storeState.foo).toEqual 'foo'
      expect(storeState.bar).toEqual 'bar'


  describe '#handleUnfollowChannelSuccess', ->

    it 'removes given channelId from list when its unfollowed', ->

      @reactor.dispatch actionTypes.FOLLOW_CHANNEL_SUCCESS, { channelId: 'foo' }
      @reactor.dispatch actionTypes.FOLLOW_CHANNEL_SUCCESS, { channelId: 'bar' }
      @reactor.dispatch actionTypes.UNFOLLOW_CHANNEL_SUCCESS, { channelId: 'foo' }

      storeState = @reactor.evaluateToJS ['FollowedPublicChannelIdsStore']

      expect(storeState.bar).toEqual 'bar'
      expect(storeState.foo).toEqual undefined
