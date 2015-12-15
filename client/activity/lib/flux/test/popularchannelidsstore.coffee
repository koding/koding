expect = require 'expect'

Reactor = require 'app/flux/base/reactor'

PopularChannelIdsStore = require 'activity/flux/stores/popularchannelidsstore'
actionTypes = require 'activity/flux/actions/actiontypes'

describe 'PopularChannelIdsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores { popularChannelIds : PopularChannelIdsStore }


  describe '#handleLoadChannelsSuccess', ->

    it 'adds popular channel ids to list when popular channels are loaded', ->

      channel1 = { id : 'koding' }
      channel2 = { id : 'qwerty' }
      channels = [ channel1, channel2 ]

      @reactor.dispatch actionTypes.LOAD_POPULAR_CHANNELS_SUCCESS, { channels }

      storeState = @reactor.evaluate ['popularChannelIds']

      expect(storeState.size).toEqual 2

      storeState = storeState.toJS()

      expect(storeState.koding).toEqual 'koding'
      expect(storeState.qwerty).toEqual 'qwerty'

      channel3 = { id : 'programming' }
      channel4 = { id : 'testing' }
      channels = [ channel3, channel4 ]

      @reactor.dispatch actionTypes.LOAD_POPULAR_CHANNELS_SUCCESS, { channels }

      storeState = @reactor.evaluate ['popularChannelIds']

      expect(storeState.size).toEqual 4

      storeState = storeState.toJS()

      expect(storeState.programming).toEqual 'programming'
      expect(storeState.testing).toEqual 'testing'
