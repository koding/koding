{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

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

      expect(storeState.foo).to.eql 'foo'
      expect(storeState.bar).to.eql 'bar'

