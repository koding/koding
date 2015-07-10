{ expect } = require 'chai'

Reactor = require 'app/flux/reactor'

MessageSearchResultsStore = require '../stores/messagesearchresultsstore'
actionTypes = require '../actions/actiontypes'

describe 'MessageSearchResultsStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores messageSearchResults : MessageSearchResultsStore

  describe '#handleSearchSuccess', ->

    it 'caches search data by given channelId and query', ->

      channelId = 123
      query1 = 'qwerty'
      data1 = ['textWithQuerty']
      @reactor.dispatch actionTypes.SEARCH_SUCCESS, {
        query : query1
        channelId
        data : data1
      }

      messageSearchResults = @reactor.evaluate ['messageSearchResults']

      expect(messageSearchResults.has channelId).to.equal yes
      expect(messageSearchResults.get(channelId).has query1).to.equal yes
      expect(messageSearchResults.get(channelId).get(query1)[0]).to.equal data1[0]


