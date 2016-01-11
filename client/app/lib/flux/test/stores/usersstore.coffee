actions              = require '../../actions/actiontypes'
expect               = require 'expect'
Reactor              = require 'app/flux/base/reactor'
UsersStore           = require '../../stores/usersstore'
generateDummyAccount = require 'app/util/generateDummyAccount'

describe 'UsersStore', ->

  beforeEach ->
    @reactor = new Reactor
    @reactor.registerStores [UsersStore]

  describe '#handleLoadSuccess', ->

    it 'loads user', ->

      account = generateDummyAccount '123', 'foouser'

      @reactor.dispatch actions.LOAD_USER_SUCCESS, { id: '123', account }

      storeState = @reactor.evaluateToJS [UsersStore.getterPath]

      expect(storeState['123']).toEqual account


  describe '#handleLoadListSuccess', ->

    it 'loads user list', ->

      account1 = generateDummyAccount '123', 'qwertyuser'
      account2 = generateDummyAccount '456', 'testuser'
      users    = [ account1, account2 ]

      @reactor.dispatch actions.SEARCH_USERS_SUCCESS, { users }

      storeState = @reactor.evaluateToJS [UsersStore.getterPath]

      expect(storeState['123']).toEqual account1
      expect(storeState['456']).toEqual account2


  describe '#handleMarkUserAsTrollSuccess', ->

    it 'marks user as troll', ->

      account = generateDummyAccount '321', 'testaccount'
      @reactor.dispatch actions.LOAD_USER_SUCCESS, { id: '321', account }
      @reactor.dispatch actions.MARK_USER_AS_TROLL_SUCCESS, account

      storeState = @reactor.evaluate [UsersStore.getterPath]

      console.log 'storeState ', storeState
      expect(storeState.getIn ['321', 'isExempt']).toEqual yes


  describe '#handleUnmarkUserAsTrollSuccess', ->

    it 'deletes troll mark from user', ->

      account          = generateDummyAccount '321', 'testaccount'
      account.isExempt = true

      @reactor.dispatch actions.LOAD_USER_SUCCESS, { id: '321', account }
      @reactor.dispatch actions.UNMARK_USER_AS_TROLL_SUCCESS, account

      storeState = @reactor.evaluate [UsersStore.getterPath]

      console.log 'storeState ', storeState
      expect(storeState.getIn ['321', 'isExempt']).toEqual no
