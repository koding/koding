expect = require 'expect'
configureStore = require 'redux-mock-store'

fixtures = require 'app/redux/services/fixtures/payment'
{ reducer } = customer = require './customer'

describe 'redux/modules/customer#reducer', ->

  it 'should return the initial state', ->

    expect(reducer(undefined, {})).toEqual null

  it 'should handle LOAD.SUCCESS', ->

    { customerWithSub } = fixtures

    state = reducer undefined,
      type: customer.LOAD.SUCCESS
      result: customerWithSub

    expect(state).toExist()
    expect(state.id).toBe(customerWithSub.id)

  it 'should handle LOAD.SUCCESS', ->

    { customerWithSub } = fixtures

    state = reducer undefined,
      type: customer.LOAD.SUCCESS
      result: customerWithSub

    expect(state).toExist()
    expect(state.id).toBe(customerWithSub.id)

  it 'should handle UPDATE.SUCCESS', ->

    { customerWithSub } = fixtures

    state = reducer undefined,
      type: customer.UPDATE.SUCCESS
      result: customerWithSub

    expect(state).toExist()
    expect(state.id).toBe(customerWithSub.id)

  it 'should handle CREATE.SUCCESS', ->

    { customerWithSub } = fixtures

    state = reducer undefined,
      type: customer.CREATE.SUCCESS
      result: customerWithSub

    expect(state).toExist()
    expect(state.id).toBe(customerWithSub.id)


  it 'should handle REMOVE.SUCCESS', ->

    { customerWithSub } = fixtures

    # first load a customer
    state = reducer undefined,
      type: customer.LOAD.SUCCESS
      result: customerWithSub

    # then send an action to remove it
    state = reducer state,
      type: customer.REMOVE.SUCCESS
      result: customerWithSub

    expect(state).toBe null


describe 'redux/modules/customer#actions', ->

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


  describe '#load', ->

    it 'should dispatch success action', ->
      mock.onGet(Endpoints.CustomerGet).reply 200, fixtures.customerWithSub

      loadAction = customer.load()

      store.dispatch(loadAction).then ->
        expect(store.getActions()).toEqual [
          { type: customer.LOAD.BEGIN }
          { type: customer.LOAD.SUCCESS, result: fixtures.customerWithSub }
        ]

    it 'it should dispatch error action', ->
      # TODO: understand how axios mock adapter errorrs work
      mock.onGet(Endpoints.CustomerGet).reply 400

      loadAction = customer.load()

      store.dispatch(loadAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe customer.LOAD.BEGIN
        expect(actions[1].type).toBe customer.LOAD.FAIL


  describe '#create', ->

    it 'should dispatch success action', ->
      mock.onPost(Endpoints.CustomerCreate).reply 200, fixtures.customerWithSub

      createAction = customer.create()

      store.dispatch(createAction).then ->
        expect(store.getActions()).toEqual [
          { type: customer.CREATE.BEGIN }
          { type: customer.CREATE.SUCCESS, result: fixtures.customerWithSub }
        ]

    it 'should dispatch fail action', ->
      mock.onPost(Endpoints.CustomerCreate).reply 400

      createAction = customer.create()

      store.dispatch(createAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe customer.CREATE.BEGIN
        expect(actions[1].type).toBe customer.CREATE.FAIL


  describe '#update', ->

    it 'should dispatch success action', ->
      mock.onPost(Endpoints.CustomerUpdate).reply 200, fixtures.customerWithSub

      updateAction = customer.update { source: 'credit_card_token_from.stripe.js' }

      store.dispatch(updateAction).then ->
        expect(store.getActions()).toEqual [
          { type: customer.UPDATE.BEGIN }
          { type: customer.UPDATE.SUCCESS, result: fixtures.customerWithSub }
        ]

    it 'should dispatch fail action', ->
      mock.onPost(Endpoints.CustomerUpdate).reply 400

      updateAction = customer.update()

      store.dispatch(updateAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe customer.UPDATE.BEGIN
        expect(actions[1].type).toBe customer.UPDATE.FAIL


  describe '#remove', ->

    it 'should dispatch success action', ->
      mock.onDelete(Endpoints.CustomerDelete).reply 200, fixtures.customerDeleted

      removeAction = customer.remove()

      store.dispatch(removeAction).then ->
        expect(store.getActions()).toEqual [
          { type: customer.REMOVE.BEGIN }
          { type: customer.REMOVE.SUCCESS, result: fixtures.customerDeleted }
        ]

    it 'should dispatch fail action', ->
      mock.onDelete(Endpoints.CustomerDelete).reply 400

      removeAction = customer.remove()

      store.dispatch(removeAction).then ->
        actions = store.getActions()
        expect(actions[0].type).toBe customer.REMOVE.BEGIN
        expect(actions[1].type).toBe customer.REMOVE.FAIL
