expect = require 'expect'
configureStore = require 'redux-mock-store'

fixtures = require 'app/redux/services/fixtures/payment'

{ reducer } = creditcard = require './creditcard'
customer = require './customer'

describe 'redux/modules/creditcard#reducer', ->

  it 'should return the initial state', ->

    expect(reducer(undefined, {})).toBe null

  it 'should handle customer success actions', ->

    fixtureCardId = fixtures.customerWithSub.sources.data[0].id

    # just to make sure mocks are still working correct.
    expect(fixtureCardId).toBe fixtures.customerWithSub.default_source

    state = reducer undefined,
      type: customer.LOAD.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toExist()
    expect(state.id).toBe fixtureCardId

    state = reducer undefined,
      type: customer.CREATE.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toExist()
    expect(state.id).toBe fixtureCardId

    state = reducer undefined,
      type: customer.UPDATE.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toExist()
    expect(state.id).toBe fixtureCardId

    # removal of customer will result in removal of sub.
    state = reducer state,
      type: customer.REMOVE.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toBe null


  it 'should handle REMOVE.SUCCESS', ->

    # first load a customer
    state = reducer undefined,
      type: customer.LOAD.SUCCESS
      result: fixtures.customerWithSub

    # then send an action to remove it
    state = reducer state,
      type: creditcard.REMOVE.SUCCESS
      result: fixtures.cardDeleted

    expect(state).toBe null


describe 'redux/modules/creditcard#actions', ->

  { Endpoints } = paymentService = require 'app/redux/services/payment'

  mockStore = configureStore [
    require('app/redux/middleware/payment')(require 'app/redux/services/payment')
    require('app/redux/middleware/promise')
  ]

  mock = store = null

  before ->
    store = mockStore({})
    mock = require('app/util/mockHttpClient')(paymentService.client)

  after -> mock.restore()

  beforeEach ->
    mock.reset()
    store.clearActions()


  describe '#remove', ->

    it 'should dispatch success action', ->
      mock
        .onDelete Endpoints.CreditCardDelete
        .reply 200, fixtures.subscriptionDeleted

      removeAction = creditcard.remove()

      store.dispatch(removeAction).then ->
        expect(store.getActions()).toEqual [
          { type: creditcard.REMOVE.BEGIN }
          { type: creditcard.REMOVE.SUCCESS, result: fixtures.subscriptionDeleted }
        ]

    it 'should dispatch fail action', ->
      mock.onDelete(Endpoints.CreditCardDelete).reply 400

      removeAction = creditcard.remove()

      store.dispatch(removeAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe creditcard.REMOVE.BEGIN
        expect(actions[1].type).toBe creditcard.REMOVE.FAIL
