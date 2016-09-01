kd      = require 'kd'
mock    = require '../../mocks/mockingjay'
nick    = require 'app/util/nick'
expect  = require 'expect'
remote  = require 'app/remote'

SearchController   = require 'app/searchcontroller'
{ mainController } = kd.singletons

SEED         = 'tu'
SEED_OPTIONS =
  showCurrentUser : no


describe 'kd.singletons.search', ->

  afterEach -> expect.restoreSpies()

  describe '::searchAccounts', ->

    it 'should call search method with arguments', (done) ->

      mainController.ready ->

        mockAccount  = mock.getMockAccount()
        { nickname } = mockAccount.profile

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

    it 'should not filter current user if showCurrentUser is yes', (done) ->

      mainController.ready ->

        mockAccount  = mock.getMockAccount()
        { nickname } = mockAccount.profile

        mock.remote.cacheableAsync.toReturnPassedParam mockAccount
        mock.search.getIndex.toReturnIndex()

        { search }   = kd.singletons
        search.ready = yes

        nickSpy     = expect.createSpy().andReturn nickname
        revertNick  = SearchController.__set__ 'nick', nickSpy

        SEED_OPTIONS.showCurrentUser = yes

        search
          .searchAccounts SEED, SEED_OPTIONS
          .then (data) ->

            found = no

            for acc in data when acc.profile.nickname is nickname
              found = yes

            expect(found).toBe yes

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
            expect(search.searchAccountsMongo).toHaveBeenCalledWith SEED, SEED_OPTIONS
            done()


    it 'should search mongo if algolia is not ready', (done) ->

      mainController.ready ->

        { search }   = kd.singletons
        search.ready = no

        expect.spyOn search, 'searchAccountsMongo'

        search
          .searchAccounts SEED, SEED_OPTIONS
          .catch ->
            expect(search.searchAccountsMongo).toHaveBeenCalledWith SEED, SEED_OPTIONS
            done()



  describe '::searchAccountsMongo', ->

    it 'should remove "@" character from the seed', (done) ->

      { search } = kd.singletons
      seed       = '@kodinguser'

      mock.remote.api.JAccount.one.toReturnAccount()
      mock.groups.getCurrentGroup.toReturnGroup()

      spy = expect.spyOn remote.api.JAccount, 'one'

      search.searchAccountsMongo(seed).then ->
        expect(spy).toHaveBeenCalledWith {
          'profile.nickname': 'kodinguser'
        }
        done()


    it 'should filter current user from the results', (done) ->

      { search } = kd.singletons

      mockAccount = mock.getMockAccount()
      mockGroup   = mock.getMockGroup()
      nickname    = mockAccount.profile.nickname

      mock.remote.api.JAccount.one.toReturnAccount()
      mock.groups.getCurrentGroup.toReturnGroup()

      expect.spyOn(mockGroup, 'isMember').andCall (account, callback) ->
        callback null, yes

      nickSpy     = expect.createSpy().andReturn nickname
      revertNick  = SearchController.__set__ 'nick', nickSpy

      search
        .searchAccountsMongo SEED
        .then (account) ->

          found = no

          for acc in account when acc.profile.nickname is nickname
            found = yes

          expect(found).toBe no

          revertNick()
          done()


    it 'should not filter current user from the results if showCurrentUser is yes', (done) ->

      { search } = kd.singletons

      mockAccount = mock.getMockAccount()
      mockGroup   = mock.getMockGroup()
      nickname    = mockAccount.profile.nickname

      mock.remote.api.JAccount.one.toReturnAccount()
      mock.groups.getCurrentGroup.toReturnGroup()

      expect.spyOn(mockGroup, 'isMember').andCall (account, callback) ->
        callback null, yes

      nickSpy     = expect.createSpy().andReturn nickname
      revertNick  = SearchController.__set__ 'nick', nickSpy

      SEED_OPTIONS.showCurrentUser = yes

      search
        .searchAccountsMongo SEED, SEED_OPTIONS
        .then (account) ->

          found = no

          for acc in account when acc.profile.nickname is nickname
            found = yes

          expect(found).toBe yes

          revertNick()
          done()
