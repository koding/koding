expect = require 'expect'
configureStore = require 'redux-mock-store'

fixtures = require 'app/redux/services/fixtures/payment'

{ reducer } = subscription = require './subscription'
customer = require './customer'

describe 'redux/modules/subscription#reducer', ->

  it 'should return the initial state', ->

    expect(reducer(undefined, {})).toBe null

  it 'should handle customer success actions', ->

    fixtureSubId = fixtures.customerWithSub.subscriptions.data[0].id

    state = reducer undefined,
      type: customer.LOAD.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toExist()
    expect(state.id).toBe fixtureSubId

    state = reducer undefined,
      type: customer.CREATE.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toExist()
    expect(state.id).toBe fixtureSubId

    state = reducer undefined,
      type: customer.UPDATE.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toExist()
    expect(state.id).toBe fixtureSubId

    # removal of customer will result in removal of sub.
    state = reducer state,
      type: customer.REMOVE.SUCCESS
      result: fixtures.customerWithSub

    expect(state).toBe null


  it 'should handle LOAD.SUCCESS', ->

    state = reducer undefined,
      type: subscription.LOAD.SUCCESS
      result: fixtures.subscription

    expect(state).toExist()
    expect(state.id).toBe fixtures.subscription.id


  it 'should handle CREATE.SUCCESS', ->

    state = reducer undefined,
      type: subscription.CREATE.SUCCESS
      result: fixtures.subscription

    expect(state).toExist()
    expect(state.id).toBe fixtures.subscription.id

  it 'should handle REMOVE.SUCCESS', ->

    # first load a customer
    state = reducer undefined,
      type: subscription.LOAD.SUCCESS
      result: fixtures.subscription

    # then send an action to remove it
    state = reducer state,
      type: subscription.REMOVE.SUCCESS
      result: fixtures.subscription

    expect(state).toBe null


describe 'redux/modules/subscription#actions', ->

  { Endpoints } = paymentService = require 'app/redux/services/payment'

  # SubscriptionDelete : "/subscription/delete"
  # SubscriptionGet    : "/subscription/get"
  # SubscriptionCreate : "/subscription/create"

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


  describe '#load', ->

    it 'should dispatch success action', ->
      mock.onGet(Endpoints.SubscriptionGet).reply 200, fixtures.subscription

      loadAction = subscription.load()

      store.dispatch(loadAction).then ->
        expect(store.getActions()).toEqual [
          { type: subscription.LOAD.BEGIN }
          { type: subscription.LOAD.SUCCESS, result: fixtures.subscription }
        ]

    it 'it should dispatch error action', ->
      # TODO: understand how axios mock adapter errorrs work
      mock.onGet(Endpoints.SubscriptionGet).reply 400

      loadAction = subscription.load()

      store.dispatch(loadAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe subscription.LOAD.BEGIN
        expect(actions[1].type).toBe subscription.LOAD.FAIL


  describe '#create', ->

    it 'should dispatch success action', ->
      mock.onPost(Endpoints.SubscriptionCreate).reply 200, fixtures.subscription

      customerId = 'cus_94rAA5D5Xax6uc'
      planId = 'p_up_to_10'

      createAction = subscription.create customerId, planId

      store.dispatch(createAction).then ->
        expect(store.getActions()).toEqual [
          { type: subscription.CREATE.BEGIN }
          { type: subscription.CREATE.SUCCESS, result: fixtures.subscription }
        ]

    it 'it should dispatch error action', ->
      # TODO: understand how axios mock adapter errorrs work
      mock.onPost(Endpoints.SubscriptionCreate).reply 400

      createAction = subscription.create()

      store.dispatch(createAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe subscription.CREATE.BEGIN
        expect(actions[1].type).toBe subscription.CREATE.FAIL


  describe '#remove', ->

    it 'should dispatch success action', ->
      mock
        .onDelete Endpoints.SubscriptionDelete
        .reply 200, fixtures.subscriptionDeleted

      removeAction = subscription.remove()

      store.dispatch(removeAction).then ->
        expect(store.getActions()).toEqual [
          { type: subscription.REMOVE.BEGIN }
          { type: subscription.REMOVE.SUCCESS, result: fixtures.subscriptionDeleted }
        ]

    it 'should dispatch fail action', ->
      mock.onDelete(Endpoints.SubscriptionDelete).reply 400

      removeAction = subscription.remove()

      store.dispatch(removeAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe subscription.REMOVE.BEGIN
        expect(actions[1].type).toBe subscription.REMOVE.FAIL
