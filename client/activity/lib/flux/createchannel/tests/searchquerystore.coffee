{ expect } = require 'chai'

Reactor = require 'app/flux/base/reactor'

SearchQueryStore = require 'activity/flux/createchannel/stores/searchquerystore'
actions = require 'activity/flux/createchannel/actions/actiontypes'

describe 'CreateNewChannelParticipantsSearchQueryStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores searchQuery : SearchQueryStore


  describe '#setQuery', ->

    it 'sets current query to a given value', ->

      query1      = 'user1'
      query2      = 'user2'

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY, { query : query1 }
      query = @reactor.evaluate(['searchQuery'])

      expect(query).to.equal query1

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY, { query: query2 }
      query = @reactor.evaluate(['searchQuery'])

      expect(query).to.equal query2


  describe '#unsetQuery', ->

    it 'clears current query', ->

      testQuery   = 'koding'

      @reactor.dispatch actions.SET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY, { query : testQuery }
      query = @reactor.evaluate(['searchQuery'])

      expect(query).to.equal testQuery

      @reactor.dispatch actions.UNSET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY
      query = @reactor.evaluate(['searchQuery'])

      expect(query).to.be.null

