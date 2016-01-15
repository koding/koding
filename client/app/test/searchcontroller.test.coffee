kd      = require 'kd'
mock    = require '../../mocks/mockingjay'
nick    = require 'app/util/nick'
expect  = require 'expect'

SearchController   = require 'app/searchcontroller'
{ mainController } = kd.singletons

SEED         = 'tu'
SEED_OPTIONS = {}

describe 'kd.singletons.search', ->

  afterEach -> expect.restoreSpies()

  describe '::searchAccounts', ->

    it 'should call search method with arguments', (done) ->

      mainController.ready ->

        mockAccount  = mock.getMockAccount()
        { nickname } = mockAccount.profile

        mock.remote.cacheableAsync.toReturnPassedParam mockAccount
        mock.search.getIndex.toReturnIndex()

        { search }   = kd.singletons
        search.ready = yes

        spy = expect.spyOn(search, 'search').andCallThrough()

        search.searchAccounts SEED, SEED_OPTIONS

        args = spy.calls.first.arguments

        expect(args[0]).toBe 'accounts'
        expect(args[1]).toBe SEED

        options = args[2]

        expect(options.hitsPerPage).toBe 10
        expect(options.restrictSearchableAttributes).toEqual [ 'nick' ]

        done()


    it 'should filter current user from the results', (done) ->

      mainController.ready ->

        mockAccount  = mock.getMockAccount()
        { nickname } = mockAccount.profile

        mock.remote.cacheableAsync.toReturnPassedParam mockAccount
        mock.search.getIndex.toReturnIndex()

        { search }   = kd.singletons
        search.ready = yes

        nickSpy     = expect.createSpy().andReturn nickname
        revertNick  = SearchController.__set__ 'nick', nickSpy

        search
          .searchAccounts SEED, SEED_OPTIONS
          .then (data) ->

            found = no

            for acc in data when acc.nick is nickname
              found = yes

            expect(found).toBe no

            revertNick()
            done()


    it 'should search mongo if algolia fails', (done) ->

      mainController.ready ->

        { search }   = kd.singletons
        search.ready = yes

        mock.search.getIndex.toReturnIndex no

        expect.spyOn search, 'searchAccountsMongo'

        search
          .searchAccounts SEED, SEED_OPTIONS
          .catch ->
            expect(search.searchAccountsMongo).toHaveBeenCalledWith SEED
            done()


    it 'should search mongo if algolia is not ready', (done) ->

      mainController.ready ->

        { search }   = kd.singletons
        search.ready = no

        expect.spyOn search, 'searchAccountsMongo'

        search
          .searchAccounts SEED, SEED_OPTIONS
          .catch ->
            expect(search.searchAccountsMongo).toHaveBeenCalledWith SEED
            done()
