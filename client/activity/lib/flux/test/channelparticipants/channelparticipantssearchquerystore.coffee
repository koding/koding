{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

ChannelParticipantsSearchQueryStore = require 'activity/flux/stores/channelparticipants/channelparticipantssearchquerystore'
actions = require 'activity/flux/actions/actiontypes'

describe 'ChannelParticipantsSearchQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores channelParticipantsSearchQuery : ChannelParticipantsSearchQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1 = 'koding'
      query2 = 'kodingen'

      @reactor.dispatch actions.SET_CHANNEL_PARTICIPANTS_QUERY, query : query1
      query = @reactor.evaluate ['channelParticipantsSearchQuery']

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CHANNEL_PARTICIPANTS_QUERY, query: query2
      query = @reactor.evaluate ['channelParticipantsSearchQuery']

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery = 'koding'

      @reactor.dispatch actions.SET_CHANNEL_PARTICIPANTS_QUERY, query : testQuery
      query = @reactor.evaluate ['channelParticipantsSearchQuery']

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_CHANNEL_PARTICIPANTS_QUERY
      query = @reactor.evaluate ['channelParticipantsSearchQuery']

      expect(query).to.be.null

