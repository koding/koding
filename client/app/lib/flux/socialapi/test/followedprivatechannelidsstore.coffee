expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

FollowedPrivateChannelIdsStore = require '../stores/followedprivatechannelidsstore'
actionTypes = require '../actions/actiontypes'

describe 'FollowedPublicChannelIdsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [FollowedPrivateChannelIdsStore]

  describe '#handleLoadChannelSuccess', ->

    it 'adds followed channel id to list when its loaded', ->

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, {
        channel: { id: 'foo' }
      }

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, {
        channel: { id: 'bar' }
      }

      storeState = @reactor.evaluateToJS ['FollowedPrivateChannelIdsStore']

      expect(storeState.foo).toEqual 'foo'
      expect(storeState.bar).toEqual 'bar'


  describe '#handleDeletePrivateChannelSuccess', ->

    it 'Removes given channelId from privateMessageIds container.', ->

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, {
        channel: { id: 'foo' }
      }

      @reactor.dispatch actionTypes.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, {
        channel: { id: 'bar' }
      }

      @reactor.dispatch actionTypes.DELETE_PRIVATE_CHANNEL_SUCCESS, { channelId: 'foo' }


      storeState = @reactor.evaluateToJS ['FollowedPrivateChannelIdsStore']

      expect(storeState.bar).toEqual 'bar'
      expect(storeState.foo).toEqual undefined
