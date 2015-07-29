actions              = require '../../actions/actiontypes'
{ expect }           = require 'chai'
Reactor              = require 'app/flux/reactor'
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

      expect(storeState['123']).to.eql account


