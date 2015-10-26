{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

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

      mockPublicChannel.isParticipant = yes
      expect(storeState.foo).to.eql mockPublicChannel


  describe 'handleLoadChannelListSuccess', ->

    it 'loads a list of popular channels', ->

       channel1 = { id : 'programming', name : 'programming' }
       channel2 = { id : 'testing', name : 'testing' }
       channels = [ channel1, channel2 ]

       @reactor.dispatch actionTypes.LOAD_POPULAR_CHANNELS_SUCCESS, { channels }

       storeState = @reactor.evaluateToJS ['ChannelsStore']

       expect(storeState.programming).to.eql channel1
       expect(storeState.testing).to.eql channel2


  describe 'handleFollowChannelSuccess', ->

    it 'follows a channel', ->

       channel  = { id : 'koding', name : 'koding', isParticipant: no }

       @reactor.dispatch actionTypes.LOAD_CHANNEL_SUCCESS, { channel }
       @reactor.dispatch actionTypes.FOLLOW_CHANNEL_SUCCESS, { channelId: 'koding' }

       storeState = @reactor.evaluate ['ChannelsStore']

       expect(storeState.getIn ['koding', 'isParticipant']).to.equal yes


  describe 'handleUnfollowChannelSuccess', ->

    it 'unfollows a channel', ->

       channel  = { id : 'koding', name : 'koding', isParticipant: yes }

       @reactor.dispatch actionTypes.LOAD_CHANNEL_SUCCESS, { channel }
       @reactor.dispatch actionTypes.UNFOLLOW_CHANNEL_SUCCESS, { channelId: 'koding' }

       storeState = @reactor.evaluate ['ChannelsStore']

       expect(storeState.getIn ['koding', 'isParticipant']).to.equal no
